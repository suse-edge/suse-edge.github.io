#!/usr/bin/env python3
"""
Update Component Versions table in release notes from release manifest.
Compares with previous version and adds bold styling (s|) for changed versions.
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
        f"release_notes_update.py requires oras>=0.2.41 (installed: {oras.__version__}). "
        f"Upgrade with: pip install --upgrade 'oras>=0.2.41'"
    )


def parse_version(version_str):
    """Parse version string into tuple for comparison."""
    version_str = version_str.lstrip('v')
    parts = re.findall(r'\d+', version_str)
    return tuple(int(p) for p in parts) if parts else (0,)


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


def fetch_release_manifests(image_ref):
    """Fetch release_images.yaml and tooling_manifest.yaml from container image using ORAS."""
    print(f"Fetching manifests from {image_ref}")

    manifest_data = {}
    client = oras.client.OrasClient()
    container = client.get_container(image_ref)
    manifest = client.get_manifest(container)

    # Handle multi-platform images
    if manifest.get('mediaType') in [
        'application/vnd.docker.distribution.manifest.list.v2+json',
        'application/vnd.oci.image.index.v1+json'
    ]:
        import platform
        machine = platform.machine().lower()
        arch_map = {'x86_64': 'amd64', 'amd64': 'amd64', 'aarch64': 'arm64', 'arm64': 'arm64'}
        target_arch = arch_map.get(machine, machine)

        for m in manifest.get('manifests', []):
            p = m.get('platform', {})
            if p.get('architecture') == target_arch and p.get('os') == 'linux':
                repo = image_ref.split(':')[0].split('@')[0]
                image_ref = f"{repo}@{m['digest']}"
                break

    with tempfile.TemporaryDirectory() as tmpdir:
        layers = client.pull(target=image_ref, outdir=tmpdir)
        for i, layer_path in enumerate(layers):
            # Look for release_images.yaml
            content = find_file_in_layer(layer_path, "release_images.yaml")
            if content:
                print(f"  ✓ Found release_images.yaml in layer {i+1}")
                manifest_data['release_images'] = yaml.safe_load(content)

            # Look for tooling_manifest.yaml
            content = find_file_in_layer(layer_path, "tooling_manifest.yaml")
            if content:
                print(f"  ✓ Found tooling_manifest.yaml in layer {i+1}")
                manifest_data['tooling_manifest'] = yaml.safe_load(content)

    if 'release_images' not in manifest_data:
        raise ValueError(f"release_images.yaml not found in {image_ref}")

    return manifest_data


def build_version_map(manifest_data):
    """Build a map of component names to versions from release_images.yaml and tooling_manifest.yaml."""
    version_map = {}
    release_images = manifest_data.get('release_images', {})
    tooling_manifest = manifest_data.get('tooling_manifest', {})

    # First, check tooling_manifest for EIB and Kiwi Builder versions
    # These are the authoritative source for tooling versions
    if 'eib' in tooling_manifest:
        eib_version = tooling_manifest['eib'].get('version', '')
        if eib_version:
            version_map['Edge Image Builder'] = eib_version
            print(f"  ✓ Found EIB version in tooling_manifest: {eib_version}")

    if 'kiwi' in tooling_manifest:
        kiwi_version = tooling_manifest['kiwi'].get('version', '')
        if kiwi_version:
            version_map['Kiwi Builder'] = kiwi_version
            print(f"  ✓ Found Kiwi Builder version in tooling_manifest: {kiwi_version}")

    # Map component display names to image patterns
    # Order matters - more specific patterns should come first
    component_patterns = {
        # Kubernetes distributions
        'K3s': r'hardened-kubernetes:v([0-9.]+)-k3s',
        'RKE2': r'hardened-kubernetes:v([0-9.]+)-rke2r',

        # Core SUSE Edge components
        'SUSE Rancher Prime': r'/rancher:v([0-9.]+)$',
        'SUSE Storage (Longhorn)': r'longhorn-manager:([0-9.]+)-',
        'SUSE Security (NeuVector)': r'/neuvector-controller:([0-9.]+)$',
        'SUSE Private Registry': r'harbor-core:([0-9.]+)-',

        # CAPI and provisioning
        'Rancher Turtles Providers (CAPI)': r'/turtles:v([0-9.]+)$',
        'Metal^3^': r'/ironic-python-agent:([0-9.]+)$',

        # Networking
        'MetalLB': r'/metallb-controller:v([0-9.]+)$',

        # Virtualization
        'KubeVirt': r'/virt-operator:([0-9.]+)-',
        'Containerized Data Importer (CDI)': r'/cdi-operator:([0-9.]+)-',

        # Operators and controllers
        'System Upgrade Controller': r'system-upgrade-controller:v([0-9.]+)$',
        'Upgrade Controller': r'/upgrade-controller:([0-9.]+)$',
        'Elemental': r'/elemental-operator:([0-9.]+)$',
        'Endpoint Copier Operator': r'/endpoint-copier-operator:([0-9.]+)$',
        'SR-IOV Network Operator': r'/sriov-network-manager:v([0-9.]+)$',

        # Tools and utilities
        'Cert-Manager': r'cert-manager-controller:v([0-9.]+)$',
        # Note: EIB and Kiwi Builder are already handled from tooling_manifest above
        # But keep patterns as fallback if tooling_manifest is not available
    }

    # Only add from release_images if not already found in tooling_manifest
    for entry in release_images.get('images', []):
        image_name = entry.get('name', '')

        for component, pattern in component_patterns.items():
            # Skip if already found from tooling_manifest
            if component in version_map:
                continue

            match = re.search(pattern, image_name)
            if match:
                version = match.group(1)
                version_map[component] = version

    return version_map


def update_component_table(content, release_version, new_versions, old_versions):
    """Update the Component Versions table for a specific release."""

    # Find the section for this release
    release_section_pattern = rf'\[#release-notes-{release_version.replace(".", "-")}\]'
    if not re.search(release_section_pattern, content):
        print(f"  ⚠ Warning: Could not find release section for {release_version}")
        return content, 0

    # Pattern to match component rows in the table
    # Matches: | Component Name | version | chart_version | artifact_location
    # or: s| Component Name s| version s| chart_version s| artifact_location

    updates = 0
    lines = content.split('\n')
    new_lines = []
    in_target_section = False
    in_component_table = False

    for i, line in enumerate(lines):
        # Check if we're in the target release section
        if release_section_pattern in line:
            in_target_section = True
            new_lines.append(line)
            continue

        # Check if we've left the target section (new release section started)
        if in_target_section and line.startswith('[#release-notes-'):
            in_target_section = False
            in_component_table = False

        # Check if we're entering the Component Versions table
        if in_target_section and '== Component Versions' in line:
            in_component_table = True
            new_lines.append(line)
            continue

        # Check if we've left the table (next major section)
        if in_component_table and line.startswith('==') and 'Component Versions' not in line:
            in_component_table = False

        # Process table rows
        if in_component_table and line.strip().startswith('|'):
            # Skip header and separator rows
            if '| Name | Version |' in line or line.strip() == '|======':
                new_lines.append(line)
                continue

            # Check each component pattern
            updated_line = line
            was_updated = False

            for component, new_version in new_versions.items():
                # Escape special regex characters in component name
                component_escaped = re.escape(component)

                # Try to match the component in the line
                if re.search(component_escaped, line):
                    old_version = old_versions.get(component, '')

                    # Check if version changed
                    if old_version and new_version != old_version:
                        # Add s| styling if not already present
                        if not line.strip().startswith('s|'):
                            # Replace first | with s| and all subsequent | with s|
                            parts = line.split('|')
                            styled_parts = ['s' + p if i > 0 and p.strip() else p
                                          for i, p in enumerate(parts)]
                            updated_line = '|'.join(styled_parts)
                            was_updated = True
                            updates += 1
                            print(f"  ✓ {component}: {old_version} → {new_version} (added bold)")

                        # Update version numbers in the line
                        # This is a simple replacement - may need refinement
                        if old_version in updated_line:
                            updated_line = updated_line.replace(old_version, new_version)

                    break

            new_lines.append(updated_line)
        else:
            new_lines.append(line)

    return '\n'.join(new_lines), updates


def main():
    parser = argparse.ArgumentParser(
        description='Update Component Versions table in release notes'
    )
    parser.add_argument(
        'release_version',
        help='Release version to update (e.g., 3.5.2)'
    )
    parser.add_argument(
        '--previous-version',
        help='Previous release version for comparison (default: auto-detect by decrementing patch version)'
    )
    parser.add_argument(
        '--image',
        default='registry.opensuse.org/isv/suse/edge/3.5/test_manifest_images/3.5/release-manifest',
        help='Container image reference without tag'
    )
    parser.add_argument(
        '--release-notes',
        default='../asciidoc/edge-book/releasenotes.adoc',
        help='Path to release notes file'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be updated without making changes'
    )

    args = parser.parse_args()

    # Determine previous version
    if args.previous_version:
        prev_version = args.previous_version
    else:
        # Try to auto-detect by decrementing patch version
        parts = args.release_version.split('.')
        if len(parts) == 3:
            prev_version = f"{parts[0]}.{parts[1]}.{int(parts[2])-1}"
            print(f"Auto-detected previous version: {prev_version}")
        else:
            print("Error: Could not auto-detect previous version. Please specify --previous-version")
            return 1

    # Fetch version maps for both releases
    print(f"\nFetching versions for {args.release_version}...")
    new_image_ref = f"{args.image}:{args.release_version}"
    new_manifest_data = fetch_release_manifests(new_image_ref)
    new_versions = build_version_map(new_manifest_data)

    print(f"\nFetching versions for {prev_version}...")
    old_image_ref = f"{args.image}:{prev_version}"
    old_manifest_data = fetch_release_manifests(old_image_ref)
    old_versions = build_version_map(old_manifest_data)

    # Compare versions
    print(f"\n=== Version Changes from {prev_version} to {args.release_version} ===")
    changes = {}
    for component, new_ver in new_versions.items():
        old_ver = old_versions.get(component, 'N/A')
        if old_ver != new_ver:
            changes[component] = (old_ver, new_ver)
            print(f"  {component}: {old_ver} → {new_ver}")

    if not changes:
        print("  No version changes detected")
        return 0

    # Read release notes file
    script_dir = Path(__file__).parent
    release_notes_path = (script_dir / args.release_notes).resolve()

    if not release_notes_path.exists():
        print(f"Error: Release notes file not found: {release_notes_path}")
        return 1

    with open(release_notes_path, 'r') as f:
        content = f.read()

    # Update the Component Versions table
    print(f"\n=== Updating {release_notes_path} ===")
    new_content, updates = update_component_table(content, args.release_version, new_versions, old_versions)

    if updates > 0:
        if not args.dry_run:
            with open(release_notes_path, 'w') as f:
                f.write(new_content)
            print(f"\n✓ Updated {updates} component(s) in release notes")
        else:
            print(f"\n✓ Would update {updates} component(s) in release notes (dry run)")
    else:
        print("\n⚠ No components were updated in the table")
        print("  Note: The component table may need to be created manually first")

    return 0


if __name__ == "__main__":
    exit(main())
