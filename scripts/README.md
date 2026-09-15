# SUSE Edge documentation scripts

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

## Update release versions (legacy)

The `versions_update.py` script updates `versions.adoc` using data from the
Factory release manifest. It is retained for compatibility; use the z-stream
generator above for the complete workflow.

```bash
./versions_update.py
```

Requires `oras>=0.2.41`, `requests`, `pyyaml`, and `jinja2`:

```bash
pip install --upgrade 'oras>=0.2.41' requests pyyaml jinja2
```
