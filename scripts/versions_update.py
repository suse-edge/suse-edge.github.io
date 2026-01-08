#!/usr/bin/env python3
"""
Generate versions.adoc from release manifest in container image.
Uses ORAS library for OCI registry interaction.
"""

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
from datetime import date
from jinja2 import Environment, FileSystemLoader
from pathlib import Path


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


def fetch_release_manifest(image_ref, target_file="release_manifest.yaml"):
    """Fetch release manifest from container image using ORAS."""
    print(f"Fetching release manifest from {image_ref}")

    client = oras.client.OrasClient()

    with tempfile.TemporaryDirectory() as tmpdir:
        layers = client.pull(target=image_ref, outdir=tmpdir)

        for i, layer_path in enumerate(layers):
            content = find_file_in_layer(layer_path, target_file)
            if content:
                print(f"✓ Found {target_file} in layer {i+1}")
                return content

    raise FileNotFoundError(f"File {target_file} not found in image")


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

    # Replace %%REVDATE%% with current date
    revision_date = date.today().strftime('%Y-%m-%d')
    output = output.replace('%%REVDATE%%', revision_date)

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
        default='registry.suse.com/edge/3.5/release-manifest',
        help='Container image reference without tag (default: registry.suse.com/edge/3.5/release-manifest)'
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

    # Fetch release manifest from container image
    manifest_yaml = fetch_release_manifest(image_ref)

    # Parse YAML
    manifest_data = yaml.safe_load(manifest_yaml)

    # Add additional version data
    # Get versions from other images in the same registry path
    registry_base = '/'.join(repository.split('/')[:-1])  # Get base path without image name

    kiwi_builder_repo = f"{registry_base}/kiwi-builder"
    kiwi_builder_version = get_latest_version_tag(kiwi_builder_repo)
    # Strip suffix after hyphen (e.g., 10.2.29.1-1.1 -> 10.2.29.1)
    manifest_data['version_kiwi_builder'] = kiwi_builder_version.split('-')[0]

    eib_repo = f"{registry_base}/edge-image-builder"
    eib_version = get_latest_version_tag(eib_repo)
    # Strip suffix after hyphen (e.g., 1.3.3-4.4 -> 1.3.3)
    manifest_data['version_eib'] = eib_version.split('-')[0]

    nessie_repo = f"{registry_base}/nessie"
    nessie_version = get_latest_version_tag(nessie_repo)
    # Strip suffix after hyphen
    manifest_data['version_nessie'] = nessie_version.split('-')[0]

    # Get upgrade-controller chart version
    # Extract major.minor from release version (e.g., 3.5.0 -> 3.5)
    release_version = manifest_data.get('spec', {}).get('releaseVersion', '')
    if release_version:
        version_parts = release_version.split('.')[:2]  # Get major.minor
        chart_prefix = version_parts[0] + '0' + version_parts[1]  # e.g., 3.5 -> 305
        # Charts are at registry.suse.com/edge/charts/upgrade-controller (not version-specific)
        registry_name = repository.split('/')[0]
        upgrade_controller_repo = f"{registry_name}/edge/charts/upgrade-controller"
        upgrade_controller_version = get_latest_version_tag_with_prefix(upgrade_controller_repo, chart_prefix)
        # Strip suffix after hyphen (e.g., 305.0.3_up0.1.3-4.1 -> 305.0.3_up0.1.3)
        manifest_data['version_upgrade_controller_chart'] = upgrade_controller_version.split('-')[0]

    # Get SUC and Fleet versions from Rancher image list
    # Extract rancher version from manifest
    rancher_version = None
    for helm in manifest_data.get('spec', {}).get('components', {}).get('workloads', {}).get('helm', []):
        if helm.get('releaseName') == 'rancher':
            rancher_version = helm.get('version')
            break

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

    # Render template
    render_template(args.template, manifest_data, args.output)


if __name__ == "__main__":
    main()
