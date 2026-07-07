#!/usr/bin/env python3
"""
Update airgap image versions in documentation files from release manifest.
Uses ORAS library for OCI registry interaction.
"""

import oras.client
import tempfile
import tarfile
import gzip
import io
import yaml
import argparse
import re
from pathlib import Path


# Same version check as versions_update.py
_MIN_ORAS = (0, 2, 41)
if tuple(int(p) for p in oras.__version__.split('.')[:3]) < _MIN_ORAS:
    raise SystemExit(
        f"airgap_images_update.py requires oras>=0.2.41 (installed: {oras.__version__}). "
        f"Upgrade with: pip install --upgrade 'oras>=0.2.41'"
    )


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


def fetch_release_images(image_ref):
    """Fetch release_images.yaml from container image using ORAS."""
    print(f"Fetching release_images.yaml from {image_ref}")

    client = oras.client.OrasClient()
    container = client.get_container(image_ref)
    manifest = client.get_manifest(container)

    # If it's a manifest list (multi-platform image), resolve to a specific platform
    if manifest.get('mediaType') in [
        'application/vnd.docker.distribution.manifest.list.v2+json',
        'application/vnd.oci.image.index.v1+json'
    ]:
        import platform
        machine = platform.machine().lower()
        arch_map = {
            'x86_64': 'amd64',
            'amd64': 'amd64',
            'aarch64': 'arm64',
            'arm64': 'arm64',
        }
        target_arch = arch_map.get(machine, machine)
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
            platform_manifest = manifest['manifests'][0]
            fallback_platform = platform_manifest.get('platform', {})
            print(f"  ⚠ {target_arch}/{target_os} not found, using {fallback_platform.get('architecture')}/{fallback_platform.get('os')}")

        # Construct image reference with digest
        repo = image_ref.split(':')[0].split('@')[0]
        digest = platform_manifest['digest']
        image_ref = f"{repo}@{digest}"
        print(f"✓ Resolved to {digest}")

    with tempfile.TemporaryDirectory() as tmpdir:
        layers = client.pull(target=image_ref, outdir=tmpdir)

        if not layers:
            raise ValueError(f"No layers found in {image_ref}")

        for i, layer_path in enumerate(layers):
            content = find_file_in_layer(layer_path, "release_images.yaml")
            if content:
                print(f"✓ Found release_images.yaml in layer {i+1}")
                return yaml.safe_load(content)

    raise ValueError(f"release_images.yaml not found in any layer of {image_ref}")


def build_image_map(release_images):
    """Build a map of image name (without tag) to full image reference."""
    image_map = {}

    for entry in release_images.get('images', []):
        full_image = entry.get('name', '')
        if ':' in full_image:
            # Split into repo and tag
            image_repo, tag = full_image.rsplit(':', 1)
            image_map[image_repo] = tag

    return image_map


def update_file_images(file_path, image_map, dry_run=False):
    """Update image versions in a file based on the image map."""
    print(f"\nProcessing {file_path}")

    if not Path(file_path).exists():
        print(f"  ⚠ File not found, skipping")
        return 0

    with open(file_path, 'r') as f:
        content = f.read()

    # Pattern to match image lines like:
    # - name: registry.rancher.com/rancher/fleet-agent:v0.15.1
    # - name: dp.apps.rancher.io/containers/longhorn-manager:1.11.2-4.1
    pattern = r'(\s+-\s+name:\s+)([a-z0-9.\-/_]+):([a-z0-9.\-+_]+)'

    updates = 0
    new_content = content

    def replace_image(match):
        nonlocal updates
        prefix = match.group(1)  # "    - name: "
        image_repo = match.group(2)  # "registry.rancher.com/rancher/fleet-agent"
        current_tag = match.group(3)  # "v0.15.1"

        if image_repo in image_map:
            new_tag = image_map[image_repo]
            if current_tag != new_tag:
                updates += 1
                print(f"  ✓ {image_repo}: {current_tag} → {new_tag}")
                return f"{prefix}{image_repo}:{new_tag}"

        return match.group(0)  # Return unchanged

    new_content = re.sub(pattern, replace_image, content)

    if updates > 0:
        if not dry_run:
            with open(file_path, 'w') as f:
                f.write(new_content)
            print(f"✓ Updated {updates} image(s) in {file_path}")
        else:
            print(f"✓ Would update {updates} image(s) in {file_path} (dry run)")
    else:
        print(f"  No changes needed in {file_path}")

    return updates


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
    def parse_version(version_str):
        version_str = version_str.lstrip('v')
        parts = re.findall(r'\d+', version_str)
        return tuple(int(p) for p in parts) if parts else (0,)

    version_tags.sort(key=parse_version, reverse=True)
    latest = version_tags[0]

    print(f"✓ Latest version: {latest}")
    return latest


def main():
    parser = argparse.ArgumentParser(
        description='Update airgap image versions in documentation files from release manifest'
    )
    parser.add_argument(
        '--image',
        default='registry.opensuse.org/isv/suse/edge/3.5/test_manifest_images/3.5/release-manifest',
        help='Container image reference without tag'
    )
    parser.add_argument(
        '--tag',
        help='Specific tag to use (if not specified, discovers latest version)'
    )
    parser.add_argument(
        '--files',
        nargs='+',
        default=[
            '../asciidoc/product/atip-management-cluster.adoc',
            '../asciidoc/components/longhorn.adoc',
            '../asciidoc/guides/air-gapped-eib-deployments.adoc'
        ],
        help='Files to update (default: atip-management-cluster.adoc, longhorn.adoc, air-gapped-eib-deployments.adoc)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be updated without making changes'
    )

    args = parser.parse_args()

    # Parse image reference - handle both with and without tag
    if ':' in args.image:
        repository, image_tag = args.image.rsplit(':', 1)
    else:
        repository = args.image
        image_tag = None

    # Determine which tag to use
    if args.tag:
        tag = args.tag
    elif image_tag:
        tag = image_tag
    else:
        tag = get_latest_version_tag(repository)

    # Build full image reference
    image_ref = f"{repository}:{tag}"

    # Fetch release_images.yaml
    release_images = fetch_release_images(image_ref)

    # Build image map
    image_map = build_image_map(release_images)
    print(f"\n✓ Built image map with {len(image_map)} images")

    # Update each file
    total_updates = 0
    for file_path in args.files:
        # Resolve relative paths
        script_dir = Path(__file__).parent
        full_path = (script_dir / file_path).resolve()
        updates = update_file_images(str(full_path), image_map, args.dry_run)
        total_updates += updates

    print(f"\n{'[DRY RUN] ' if args.dry_run else ''}Total: {total_updates} image(s) updated across {len(args.files)} file(s)")


if __name__ == "__main__":
    main()
