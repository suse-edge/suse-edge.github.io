# SUSE Edge Documentation Update Scripts

These scripts simplify release-related documentation maintenance.

## Generate z-stream release updates

`generate_zstream_release_updates.py` uses the release manifest container as
the source of truth and works on any release branch that has the expected
documentation files. It updates:

- version attributes in `asciidoc/edge-book/versions.adoc`;
- existing image tags in the known embedded artifact registry examples;
- the component table and artifact references when the target release-notes
  section already exists.

The script deliberately leaves narrative release notes, lifecycle dates, CVEs,
known issues, ambiguous image choices, and additions/removals from curated
image examples for manual review. Migration documentation also keeps pointing
at the initial `x.y.0` release and is not changed for z-stream releases.

PyYAML is the only Python dependency. `--container-image` also requires Podman
or Docker. Container tags are pulled on every run so mutable OBS test tags are
refreshed; use `--skip-pull` only when intentionally using a cached image.

```bash
python3 -m pip install PyYAML

# Preview changes from the release manifest image.
./scripts/generate_zstream_release_updates.py \
  --container-image \
  registry.opensuse.org/isv/suse/edge/3.6/test_manifest_images/3.6/release-manifest:3.6.1 \
  --release-date 2026-06-26 \
  --show-diff

# Apply the reviewed changes.
./scripts/generate_zstream_release_updates.py \
  --container-image \
  registry.opensuse.org/isv/suse/edge/3.6/test_manifest_images/3.6/release-manifest:3.6.1 \
  --release-date 2026-06-26 \
  --write
```

Alternative manifest sources are supported:

```bash
# Extracted release manifest files.
./scripts/generate_zstream_release_updates.py \
  --manifest-dir /path/to/release-manifest-image \
  --show-diff

# Raw release_manifest.yaml URL. Sibling manifest files are downloaded too.
./scripts/generate_zstream_release_updates.py \
  --manifest-url https://example.test/path/release_manifest.yaml \
  --show-diff

# A ref in a local Factory checkout.
./scripts/generate_zstream_release_updates.py \
  --factory-repo /path/to/Factory \
  --factory-ref upstream/3.6 \
  --show-diff
```

The default mode is a dry run. Use `--write` to modify files or `--check` in CI
to fail when generated changes are pending.

The exact source is recorded in `asciidoc/edge-book/versions.adoc` as a
`// Source: ...` comment and is also printed in the command output.

## Generate a new minor release

`generate_minor_release_updates.py` accepts the same manifest sources, but
requires an `x.y.0` release manifest. In addition to the common manifest-driven
updates, it changes the documentation family in the book headers, versioned
links, migration attributes, release-note anchors, selected documentation
URLs, and the release date in the legacy `version-matrix.adoc` when that file
exists on the target branch.

```bash
# Preview a new 3.7.0 documentation release from the Factory manifest image.
./scripts/generate_minor_release_updates.py \
  --container-image \
  registry.opensuse.org/isv/suse/edge/factory/test_manifest_images/release-manifest:3.7.0 \
  --release-date 2026-11-20 \
  --show-diff

# Apply after reviewing the generated and manual-change checklists.
./scripts/generate_minor_release_updates.py \
  --container-image \
  registry.opensuse.org/isv/suse/edge/factory/test_manifest_images/release-manifest:3.7.0 \
  --release-date 2026-11-20 \
  --write
```

As with z-stream releases, release-note prose, lifecycle dates, CVEs, known
issues, and one-off documentation/terminology changes remain manual.

## Existing branch-specific scripts

The `release-3.6` branch also contains the earlier `versions_update.py`,
`airgap_images_update.py`, and `release_notes_update.py` workflow. It is
retained for compatibility; use the generators above for the complete
manifest-driven workflow. The existing scripts require Python 3 and these
additional dependencies:

```bash
python3 -m venv venv
source venv/bin/activate
pip install 'oras>=0.2.41' requests jinja2 pyyaml
```

## Scripts

### versions_update.py

Updates the `versions.adoc` file with component versions from a release manifest container image.

**Usage:**

```bash
# Use latest version (auto-discover)
python3 versions_update.py

# Use specific version
python3 versions_update.py --tag 3.6.1

# Use custom image repository
python3 versions_update.py --image registry.suse.com/edge/3.6/release-manifest --tag 3.6.1

# Custom template and output paths
python3 versions_update.py --tag 3.6.1 \
  --template ../asciidoc/edge-book/versions.adoc.j2 \
  --output ../asciidoc/edge-book/versions.adoc
```

**What it does:**
- Fetches release manifest YAML files from a container image
- Extracts component versions (Rancher, Longhorn, NeuVector, Fleet, etc.)
- Queries Rancher image lists for SUC and Fleet versions
- Discovers nessie version from registry
- Renders a Jinja2 template with all collected versions
- Outputs the final `versions.adoc` file

**Default image:** `registry.opensuse.org/isv/suse/edge/3.6/test_manifest_images/3.6/release-manifest`

### airgap_images_update.py

Updates hardcoded container image versions in airgap deployment documentation files.

**Usage:**

```bash
# Dry run (preview changes without making them)
python3 airgap_images_update.py --tag 3.6.1 --dry-run

# Update files with latest version (auto-discover)
python3 airgap_images_update.py

# Update files with specific version
python3 airgap_images_update.py --tag 3.6.1

# Update specific files only
python3 airgap_images_update.py --tag 3.6.1 --files ../asciidoc/product/atip-management-cluster.adoc

# Custom image repository
python3 airgap_images_update.py --image registry.suse.com/edge/3.6/release-manifest --tag 3.6.1
```

**What it does:**
- Fetches `release_images.yaml` from a container image
- Builds a map of all container images and their tags
- Updates image versions in documentation files using regex pattern matching
- Reports all changes made

**Default files updated:**
- `../asciidoc/product/atip-management-cluster.adoc`
- `../asciidoc/components/longhorn.adoc`
- `../asciidoc/guides/air-gapped-eib-deployments.adoc`

**Default image:** `registry.opensuse.org/isv/suse/edge/3.6/test_manifest_images/3.6/release-manifest`

### release_notes_update.py

Updates the Component Versions table in release notes by comparing versions between releases and adding bold styling for changed components.

**Usage:**

```bash
# Update release notes for version 3.6.1 (compares with 3.6.0)
python3 release_notes_update.py 3.6.1

# Dry run (preview changes)
python3 release_notes_update.py 3.6.1 --dry-run

# Specify previous version explicitly
python3 release_notes_update.py 3.6.1 --previous-version 3.6.0

# Custom release notes file
python3 release_notes_update.py 3.6.1 --release-notes ../asciidoc/edge-book/releasenotes.adoc
```

**What it does:**
- Fetches `release_images.yaml` and `tooling_manifest.yaml` for both the new and previous release versions
- Extracts component versions from both manifests:
  - EIB and Kiwi Builder versions from `tooling_manifest.yaml` (authoritative source)
  - All other component versions from `release_images.yaml`
- Compares component versions between releases
- Identifies which components changed
- Adds bold styling (`s|`) to changed components in the release notes table
- Reports all detected changes

**Default file updated:**
- `../asciidoc/edge-book/releasenotes.adoc`

**Default image:** `registry.opensuse.org/isv/suse/edge/3.6/test_manifest_images/3.6/release-manifest`

**Note:** This script expects the Component Versions table to already exist in the release notes. You'll need to manually create the initial table structure for a new release before running this script.

## Typical Workflow for a New Release

For a new z-stream release (e.g., 3.6.1):

```bash
# 1. Activate the virtual environment
cd scripts
source venv/bin/activate

# 2. Update versions.adoc
python3 versions_update.py --tag 3.6.1

# 3. Preview airgap image updates
python3 airgap_images_update.py --tag 3.6.1 --dry-run

# 4. Apply airgap image updates
python3 airgap_images_update.py --tag 3.6.1

# 5. Manually create the release notes section for 3.6.1
# - Copy the previous release section as a template
# - Update release dates, summary, features, bug fixes, etc.
# - Create the Component Versions table (copy from previous release)

# 6. Update Component Versions table in release notes
python3 release_notes_update.py 3.6.1 --dry-run  # Preview
python3 release_notes_update.py 3.6.1            # Apply

# 7. Review all changes
cd ..
git diff

# 8. Commit the changes
git add -A
git commit -m "Update documentation for release 3.6.1"
```

## Notes

- Both scripts support multi-platform container images (automatically selects the appropriate architecture)
- The scripts handle ORAS bearer-token challenges for registries
- Credential helper warnings can be ignored (they don't affect functionality)
- Always review changes with `git diff` before committing
- Some manual updates may still be needed for release notes and specific documentation sections

## Troubleshooting

**Issue:** `ModuleNotFoundError: No module named 'oras'`
- **Solution:** Make sure you're in the virtual environment and dependencies are installed:
  ```bash
  source venv/bin/activate
  pip install 'oras>=0.2.41' requests jinja2 pyyaml
  ```

**Issue:** `oras version too old`
- **Solution:** Upgrade oras:
  ```bash
  pip install --upgrade 'oras>=0.2.41'
  ```

**Issue:** Docker credential helper warnings
- **Impact:** These are warnings only and don't affect the script functionality
- **Cause:** The ORAS library tries to use Docker credentials but falls back to anonymous access for public registries
Requires `oras>=0.2.41`, `requests`, `pyyaml`, and `jinja2`:

```bash
pip install --upgrade 'oras>=0.2.41' requests pyyaml jinja2
```
