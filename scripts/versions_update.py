#!/usr/bin/env python3
"""
Generate versions.adoc from release manifest in container image.
Uses ORAS library for OCI registry interaction.
"""

import oras
import oras.client
import requests
import tempfile
import tarfile
import gzip
import io
import yaml
import argparse
import re
import hashlib
import json
import base64
import platform
from datetime import date
from jinja2 import Environment, FileSystemLoader
from pathlib import Path


# 0.2.41 is the first release where client.get_manifest() both accepts
# manifest-list / image-index media types by default and makes schema
# validation opt-in. Earlier versions reject multi-platform manifests
# with a 400 "Schema 2 manifest not supported by client" from registries
# such as registry.suse.com.
_MIN_ORAS = (0, 2, 41)
if tuple(int(p) for p in oras.__version__.split('.')[:3]) < _MIN_ORAS:
    raise SystemExit(
        f"versions_update.py requires oras>=0.2.41 (installed: {oras.__version__}). "
        f"Upgrade with: pip install --upgrade 'oras>=0.2.41'"
    )


def parse_version(version_str):
    """Parse version string into tuple for comparison."""
    # Remove 'v' prefix if present
    version_str = version_str.lstrip('v')

    # Extract numeric parts
    parts = re.findall(r'\d+', version_str)
    return tuple(int(p) for p in parts) if parts else (0,)


def get_latest_version_tag(repository):
    """Get the latest version tag from the repository."""
    client = oras.client.OrasClient()

    print(f"Discovering tags for {repository}")
    tags = client.get_tags(repository)

    # Filter out non-version tags (signatures, attestations)
    version_tags = [
        tag for tag in tags
        if not tag.endswith(('.sig', '.att')) and re.match(r'^\d+\.\d+', tag)
    ]

    if not version_tags:
        raise ValueError(f"No version tags found in {repository}")

    # Sort by semantic version
    version_tags.sort(key=parse_version, reverse=True)
    latest = version_tags[0]

    print(f"✓ Latest version: {latest}")
    return latest


def get_latest_version_tag_with_prefix(repository, prefix):
    """Get the latest version tag from the repository that starts with the given prefix."""
    client = oras.client.OrasClient()

    print(f"Discovering tags for {repository} with prefix {prefix}")
    tags = client.get_tags(repository)

    # Filter for tags with the prefix, excluding signatures and attestations
    version_tags = [
        tag for tag in tags
        if tag.startswith(prefix) and not tag.endswith(('.sig', '.att'))
    ]

    if not version_tags:
        raise ValueError(f"No version tags found with prefix {prefix} in {repository}")

    # Sort by semantic version
    version_tags.sort(key=parse_version, reverse=True)
    latest = version_tags[0]

    print(f"✓ Latest version with prefix {prefix}: {latest}")
    return latest


def find_file_in_layer(layer_path, target_file):
    """Search for a file in a gzipped tar layer."""
    with open(layer_path, 'rb') as f:
        layer_data = f.read()

    try:
        stream = io.BytesIO(gzip.decompress(layer_data))
    except:
        stream = io.BytesIO(layer_data)

    try:
        with tarfile.open(fileobj=stream, mode='r') as tar:
            for member in tar.getmembers():
                if member.name.lstrip('/') == target_file.lstrip('/'):
                    f = tar.extractfile(member)
                    return f.read().decode('utf-8') if f else None
    except:
        pass
    return None


def fetch_release_manifest(image_ref):
    """Fetch release manifest from container image using ORAS."""
    print(f"Fetching release manifest from {image_ref}")

    manifest_data = {}
    image_digest = None
    client = oras.client.OrasClient()

    # client.get_manifest already accepts both manifest-list and
    # single-image media types, and ORAS handles the bearer-token
    # challenge that registries such as registry.suse.com issue even
    # for anonymous pulls.
    container = client.get_container(image_ref)
    manifest = client.get_manifest(container)

    # If it's a manifest list (multi-platform image), resolve to a specific platform
    if manifest.get('mediaType') in [
        'application/vnd.docker.distribution.manifest.list.v2+json',
        'application/vnd.oci.image.index.v1+json'
    ]:
        # Detect current system architecture
        machine = platform.machine().lower()
        # Map Python's platform names to Docker/OCI architecture names
        arch_map = {
            'x86_64': 'amd64',
            'amd64': 'amd64',
            'aarch64': 'arm64',
            'arm64': 'arm64',
            'armv7l': 'arm',
            'armv6l': 'arm',
        }
        target_arch = arch_map.get(machine, machine)
        # Always use 'linux' OS for container images, even on macOS/Windows
        target_os = 'linux'

        print(f"✓ Detected multi-platform image, selecting {target_arch}/{target_os} platform")

        # Find matching platform manifest
        platform_manifest = None
        for m in manifest.get('manifests', []):
            p = m.get('platform', {})
            if p.get('architecture') == target_arch and p.get('os') == target_os:
                platform_manifest = m
                break

        if not platform_manifest:
            # Fall back to first manifest if target platform not found
            platform_manifest = manifest['manifests'][0]
            fallback_platform = platform_manifest.get('platform', {})
            print(f"  ⚠ {target_arch}/{target_os} not found, using {fallback_platform.get('architecture')}/{fallback_platform.get('os')}")

        # Construct image reference with digest
        repo = image_ref.split(':')[0].split('@')[0]  # Remove tag or digest
        digest = platform_manifest['digest']
        image_digest = digest
        image_ref = f"{repo}@{digest}"
        print(f"✓ Resolved to {digest}")

        # Get the platform-specific manifest to extract config
        container = client.get_container(image_ref)
        manifest = client.get_manifest(container)
    else:
        # For single-platform images, compute digest from manifest
        manifest_json = json.dumps(manifest, separators=(',', ':'), sort_keys=True)
        digest_hash = hashlib.sha256(manifest_json.encode('utf-8')).hexdigest()
        image_digest = f"sha256:{digest_hash}"

    # Extract image config to get labels (including org.opencontainers.image.created)
    config_digest = manifest.get('config', {}).get('digest')
    if config_digest:
        try:
            response = client.get_blob(container, config_digest)
            response.raise_for_status()
            config = response.json()

            # Extract the org.opencontainers.image.created label
            labels = config.get('config', {}).get('Labels', {})
            created_label = labels.get('org.opencontainers.image.created', '')
            if created_label:
                print(f"✓ Found org.opencontainers.image.created label: {created_label}")
                manifest_data["image_created"] = created_label
        except Exception as e:
            print(f"  ⚠ Warning: Could not fetch image config for created label: {e}")

    with tempfile.TemporaryDirectory() as tmpdir:
        layers = client.pull(target=image_ref, outdir=tmpdir)

        if not layers:
            raise ValueError(f"No layers found in {image_ref}")

        for i, layer_path in enumerate(layers):
            content = find_file_in_layer(layer_path, "release_manifest.yaml")
            if content:
                print(f"✓ Found release_manifest.yaml in layer {i+1}")
                manifest_data["release_manifest"] = yaml.safe_load(content)
            content = find_file_in_layer(layer_path, "tooling_manifest.yaml")
            if content:
                print(f"✓ Found tooling_manifest.yaml in layer {i+1}")
                manifest_data["tooling_manifest"] = yaml.safe_load(content)
            content = find_file_in_layer(layer_path, "release_images.yaml")
            if content:
                print(f"✓ Found release_images.yaml in layer {i+1}")
                manifest_data["release_images"] = yaml.safe_load(content)

    if "release_manifest" not in manifest_data:
        raise ValueError(f"release_manifest.yaml not found in any layer of {image_ref}")

    return manifest_data, image_digest


def get_image_version_from_rancher(rancher_version, image_name):
    """Get image version from Rancher image list."""
    url = f"https://prime.ribs.rancher.io/rancher/v{rancher_version}/rancher-images.txt"

    response = requests.get(url)
    response.raise_for_status()

    search_pattern = f"{image_name}:"
    for line in response.text.splitlines():
        if search_pattern in line and not line.startswith('#'):
            # Extract tag after colon
            tag = line.split(':')[-1].strip()
            print(f"✓ Found {image_name} version: {tag}")
            return tag

    raise ValueError(f"{image_name} not found in rancher-images.txt for v{rancher_version}")


def get_image_tag_from_release_images(release_images, image_name):
    """Find an image entry in release_images.yaml and return its tag.

    release_images.yaml is shipped alongside release_manifest.yaml in the
    release-manifest OCI image and lists every image referenced by the
    release with its full <repository>:<tag>. Look up by trailing image
    name (e.g. "ironic-python-agent") and return the tag portion.
    """
    suffix = f"/{image_name}:"
    for entry in (release_images or {}).get('images', []):
        ref = entry.get('name', '')
        if suffix in ref:
            tag = ref.rsplit(':', 1)[-1]
            print(f"✓ Found {image_name} version: {tag}")
            return tag

    raise ValueError(f"{image_name} not found in release_images.yaml")


def get_suc_chart_version_from_rancher(rancher_version):
    """Get system-upgrade-controller chart version from Rancher Dockerfile."""
    url = f"https://raw.githubusercontent.com/rancher/rancher/v{rancher_version}/package/Dockerfile"

    response = requests.get(url)
    response.raise_for_status()

    for line in response.text.splitlines():
        if 'CATTLE_SYSTEM_UPGRADE_CONTROLLER_CHART_VERSION' in line:
            # Extract version from ENV line (format: ENV CATTLE_SYSTEM_UPGRADE_CONTROLLER_CHART_VERSION=108.0.0)
            version = line.split('=')[-1].strip()
            print(f"✓ Found system-upgrade-controller chart version: {version}")
            return version

    raise ValueError(f"CATTLE_SYSTEM_UPGRADE_CONTROLLER_CHART_VERSION not found in Dockerfile for v{rancher_version}")

def render_template(template_path, manifest_data, output_path):
    """Render Jinja2 template with manifest data."""
    template_file = Path(template_path)

    # Load template
    env = Environment(loader=FileSystemLoader(template_file.parent))
    template = env.get_template(template_file.name)

    # Render template with manifest data
    output = template.render(manifest_data)

    # Write output
    output_file = Path(output_path)
    output_file.write_text(output)
    print(f"✓ Generated {output_path}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate versions.adoc from release manifest in container image'
    )
    parser.add_argument(
        '--image',
        default='registry.opensuse.org/isv/suse/edge/3.6/test_manifest_images/3.6/release-manifest',
        help='Container image reference without tag (default: registry.opensuse.org/isv/suse/edge/factory/test_manifest_images/release-manifest)'
    )
    parser.add_argument(
        '--tag',
        help='Specific tag to use (if not specified, discovers latest version)'
    )
    parser.add_argument(
        '--template',
        default='../asciidoc/edge-book/versions.adoc.j2',
        help='Path to Jinja2 template (default: ../asciidoc/edge-book/versions.adoc.j2)'
    )
    parser.add_argument(
        '--output',
        default='../asciidoc/edge-book/versions.adoc',
        help='Output file path (default: ../asciidoc/edge-book/versions.adoc)'
    )

    args = parser.parse_args()

    # Parse image reference - handle both with and without tag
    if ':' in args.image:
        # Tag included in --image, split it
        repository, image_tag = args.image.rsplit(':', 1)
    else:
        repository = args.image
        image_tag = None

    # Determine which tag to use
    if args.tag:
        # Use explicit --tag parameter
        tag = args.tag
    elif image_tag:
        # Use tag from --image parameter
        tag = image_tag
    else:
        # Discover latest tag
        tag = get_latest_version_tag(repository)

    # Build full image reference
    image_ref = f"{repository}:{tag}"

    # Fetch release manifest data from container image
    manifest_data_all, image_digest = fetch_release_manifest(image_ref)

    # Parse YAML
    manifest_data = manifest_data_all["release_manifest"]
    tooling_data = manifest_data_all["tooling_manifest"]

    # Add revision metadata
    manifest_data['revision_image_ref'] = image_ref

    # Add additional version data from tooling manifest
    manifest_data['version_kiwi_builder'] = tooling_data.get('kiwi', {}).get('version', '')
    manifest_data['version_eib'] = tooling_data.get('eib', {}).get('version', '')

    # Get nessie version from registry (not in tooling manifest)
    registry_base = '/'.join(repository.split('/')[:-1])  # Get base path without image name
    images_base = registry_base.replace("test_manifest_images", "images")
    nessie_repo = f"{images_base}/nessie"
    try:
        nessie_version = get_latest_version_tag(nessie_repo)
        # Strip suffix after hyphen
        manifest_data['version_nessie'] = nessie_version.split('-')[0]
    except Exception as e:
        print(f"  ⚠ Warning: Could not fetch nessie version from {nessie_repo}: {e}")
        manifest_data['version_nessie'] = ''

    # Get SUC and Fleet versions from Rancher image list
    # Extract rancher version from manifest
    rancher_version = None
    for helm in manifest_data.get('spec', {}).get('components', {}).get('workloads', {}).get('helm', []):
        if helm.get('releaseName') == 'rancher':
            rancher_version = helm.get('version')
            break

    # Derive the ironic-python-agent (IPA) image version from
    # release_images.yaml, which lists the full image reference shipped
    # with this release manifest.
    release_images = manifest_data_all.get('release_images')
    if release_images:
        try:
            manifest_data['version_ipa'] = get_image_tag_from_release_images(
                release_images, 'ironic-python-agent'
            )
        except Exception as e:
            print(f"  ⚠ Warning: Could not derive IPA version from release_images.yaml: {e}")
            manifest_data['version_ipa'] = ''
    else:
        print("⚠ Warning: release_images.yaml not found, skipping IPA version")
        manifest_data['version_ipa'] = ''

    if rancher_version:
        print(f"Fetching Rancher image list from https://prime.ribs.rancher.io/rancher/v{rancher_version}/rancher-images.txt")
        suc_version = get_image_version_from_rancher(rancher_version, 'rancher/system-upgrade-controller')
        manifest_data['version_suc'] = suc_version

        fleet_version = get_image_version_from_rancher(rancher_version, 'rancher/fleet')
        manifest_data['version_fleet'] = fleet_version

        suc_chart_version = get_suc_chart_version_from_rancher(rancher_version)
        manifest_data['version_suc_chart'] = suc_chart_version
    else:
        print("⚠ Warning: Rancher version not found in manifest, skipping SUC and Fleet versions")

    # Define revision_date from image created label (for reproducibility)
    # Fall back to current date if label not found
    if 'image_created' in manifest_data_all and manifest_data_all['image_created']:
        # Parse ISO 8601 timestamp and extract date portion
        created_timestamp = manifest_data_all['image_created']
        # The label should be in ISO 8601 format (e.g., "2024-03-15T10:30:45Z")
        # Extract just the date part (YYYY-MM-DD)
        revision_date = created_timestamp.split('T')[0]
        print(f"✓ Using revision date from image created label: {revision_date}")
        manifest_data['revision_date'] = revision_date
    else:
        print(f"  ⚠ Warning: Image created label not found, using current date")
        manifest_data['revision_date'] = date.today().strftime('%Y-%m-%d')

    # Render template
    render_template(args.template, manifest_data, args.output)


if __name__ == "__main__":
    main()
