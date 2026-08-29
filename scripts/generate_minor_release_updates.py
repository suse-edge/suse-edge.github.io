#!/usr/bin/env python3
"""Generate deterministic documentation updates for a new SUSE Edge minor release.

This script builds on generate_zstream_release_updates.py for manifest loading,
version attributes, image examples, and release-note component tables. It adds
the documentation-family transition needed for an x.y.0 release.
"""

from __future__ import annotations

import argparse
import re
import sys
import tempfile
from pathlib import Path
from typing import Callable

import generate_zstream_release_updates as common


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate SUSE Edge minor-release documentation updates from release manifest data."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        "--container-image",
        help=(
            "Release manifest image, for example "
            "registry.opensuse.org/isv/suse/edge/factory/test_manifest_images/"
            "release-manifest:3.7.0."
        ),
    )
    source.add_argument(
        "--manifest-dir",
        type=Path,
        help="Directory containing the three release manifest YAML files.",
    )
    source.add_argument(
        "--manifest-url",
        help=(
            "Raw URL to release_manifest.yaml. The sibling release_images.yaml and "
            "tooling_manifest.yaml files are downloaded from the same URL directory."
        ),
    )
    source.add_argument(
        "--factory-ref",
        help="Factory Git ref containing release-manifest-image, for example upstream/main.",
    )

    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--write", action="store_true", help="Write generated changes.")
    mode.add_argument(
        "--check",
        action="store_true",
        help="Exit non-zero when generated changes differ from the working tree.",
    )

    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Documentation repository root. Defaults to this script's repository.",
    )
    parser.add_argument(
        "--factory-repo",
        type=Path,
        help="Local Factory repository. Required with --factory-ref.",
    )
    parser.add_argument(
        "--container-engine",
        choices=("podman", "docker"),
        help="Container engine for --container-image. Defaults to podman, then docker.",
    )
    parser.add_argument(
        "--skip-pull",
        action="store_true",
        help="Do not refresh --container-image; use the cached image.",
    )
    parser.add_argument(
        "--release-date",
        type=common.iso_date,
        help="Release date in YYYY-MM-DD form. Updates revdate attributes when supplied.",
    )
    parser.add_argument(
        "--show-diff",
        action="store_true",
        help="Print unified diffs for generated changes.",
    )
    return parser.parse_args()


def asciidoc_attribute(text: str, name: str) -> str | None:
    match = re.search(rf"^:{re.escape(name)}:\s*(\S+)\s*$", text, flags=re.MULTILINE)
    return match.group(1) if match else None


def version_family(version: str | None) -> str | None:
    if not version:
        return None
    match = re.match(r"^v?(\d+\.\d+)", version)
    return match.group(1) if match else None


def update_book_header(
    text: str, release_family: str, release_date: str | None
) -> str:
    updated = common.replace_asciidoc_attribute(text, "version", release_family)
    if release_date:
        updated = common.replace_asciidoc_attribute(updated, "revdate", release_date)
    return updated


def update_links(
    text: str, release: common.ReleaseData, release_date: str | None
) -> str:
    updated = text
    rancher = common.chart_version(release.charts, "rancher")
    rancher_family = version_family(rancher)
    turtles_chart = common.chart_version(release.charts, "rancher-turtles-providers")
    turtles_family = version_family(common.upstream_chart_version(turtles_chart))
    if rancher_family:
        updated = common.replace_asciidoc_attribute(
            updated, "rancher-docs-version", f"v{rancher_family}"
        )
    if turtles_family:
        updated = common.replace_asciidoc_attribute(
            updated, "rancher-turtles-docs-version", f"v{turtles_family}"
        )
    if release_date:
        updated = common.replace_asciidoc_attribute(updated, "revdate", release_date)
    return updated


def update_migration(
    text: str,
    release: common.ReleaseData,
    previous_release_family: str,
) -> str:
    updated = common.replace_asciidoc_attribute(
        text, "previous-edge-version", previous_release_family
    )
    updated = common.replace_asciidoc_attribute(
        updated, "static-edge-version", release.release_version
    )
    updated = common.replace_asciidoc_attribute(
        updated, "static-fleet-examples-tag", f"release-{release.release_version}"
    )
    target_anchor = f"release-notes-{release.release_family.replace('.', '-')}-0"
    return re.sub(r"release-notes-\d+-\d+-0", target_anchor, updated)


def update_documentation_family_urls(text: str, release_family: str) -> str:
    return re.sub(
        r"(documentation\.suse\.com/suse-edge/)\d+\.\d+(/)",
        rf"\g<1>{release_family}\2",
        text,
    )


def collect_minor_updates(
    repo_root: Path,
    release: common.ReleaseData,
    release_date: str | None,
    source_label: str,
) -> tuple[dict[Path, str], list[str]]:
    updates, notes = common.collect_updates(
        repo_root, release, release_date, source_label
    )

    versions_path = repo_root / "asciidoc/edge-book/versions.adoc"
    original_versions = versions_path.read_text(encoding="utf-8")
    current_family = asciidoc_attribute(original_versions, "version-edge-registry")

    migration_path = repo_root / "asciidoc/day2/migration.adoc"
    migration_previous = None
    if migration_path.is_file():
        migration_previous = asciidoc_attribute(
            migration_path.read_text(encoding="utf-8"), "previous-edge-version"
        )
    previous_family = (
        current_family
        if current_family and current_family != release.release_family
        else migration_previous
    )
    if not previous_family:
        raise RuntimeError("could not determine the previous documentation release family")

    def update_file(relative: str, transform: Callable[[str], str]) -> None:
        path = repo_root / relative
        if not path.is_file():
            return
        old = path.read_text(encoding="utf-8")
        base = updates.get(path, old)
        new = transform(base)
        if new != old:
            updates[path] = new
        else:
            updates.pop(path, None)

    update_file(
        "asciidoc/edge-book/versions.adoc",
        lambda text: common.replace_asciidoc_attribute(
            text, "revnumber", release.release_family
        ),
    )
    for book in ("asciidoc/edge-book/edge.adoc", "asciidoc/edge-book/telco.adoc"):
        update_file(
            book,
            lambda text: update_book_header(
                text, release.release_family, release_date
            ),
        )
    update_file(
        "asciidoc/edge-book/links.adoc",
        lambda text: update_links(text, release, release_date),
    )
    if release_date:
        update_file(
            "asciidoc/edge-book/version-matrix.adoc",
            lambda text: common.replace_asciidoc_attribute(
                text, "revdate", release_date
            ),
        )
    update_file(
        "asciidoc/day2/migration.adoc",
        lambda text: update_migration(text, release, previous_family),
    )
    update_file(
        "asciidoc/tips/metal3.adoc",
        lambda text: update_documentation_family_urls(
            text, release.release_family
        ),
    )

    if not release_date:
        notes.insert(
            0,
            "Supply --release-date to update revdate attributes for the new minor release.",
        )
    notes.append(
        "Review one-off terminology, structure, feature, and cross-reference changes manually; "
        "they are not release-manifest data."
    )
    return updates, notes


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    if not (repo_root / "asciidoc/edge-book/versions.adoc").is_file():
        print(f"error: {repo_root} does not look like the documentation repository root", file=sys.stderr)
        return 2

    temp_dir: tempfile.TemporaryDirectory[str] | None = None
    try:
        if args.container_image:
            temp_dir = common.extract_manifest_container(
                args.container_image, args.container_engine, args.skip_pull
            )
            manifest_dir = Path(temp_dir.name)
            source_label = args.container_image
        elif args.manifest_url:
            temp_dir = common.extract_manifest_url(args.manifest_url)
            manifest_dir = Path(temp_dir.name)
            source_label = args.manifest_url
        elif args.factory_ref:
            if not args.factory_repo:
                raise RuntimeError("--factory-repo is required with --factory-ref")
            temp_dir = common.extract_factory_ref(
                args.factory_repo.resolve(), args.factory_ref
            )
            manifest_dir = Path(temp_dir.name) / "release-manifest-image"
            source_label = f"Factory {args.factory_ref}"
        else:
            manifest_dir = common.validate_manifest_dir(args.manifest_dir.resolve())
            source_label = str(manifest_dir)

        release = common.build_release_data(manifest_dir)
        if not release.release_version.endswith(".0"):
            raise RuntimeError(
                f"minor release generator requires an x.y.0 manifest, got {release.release_version}"
            )

        updates, notes = collect_minor_updates(
            repo_root, release, args.release_date, source_label
        )
        print(
            f"Generated new-minor documentation updates for SUSE Edge {release.release_version} "
            f"(RKE2 {release.rke2_version}, K3s {release.k3s_version})."
        )
        print(f"Release manifest source: {source_label}")
        common.print_summary(
            updates,
            notes,
            repo_root,
            args.show_diff or (not args.write and not args.check),
        )

        if args.check:
            return 1 if updates else 0
        if args.write:
            for path, content in updates.items():
                path.write_text(content, encoding="utf-8")
            if updates:
                print("Updated files written.")
        elif updates:
            print("Dry-run only. Re-run with --write to update files.")
        return 0
    except RuntimeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    finally:
        if temp_dir:
            temp_dir.cleanup()


if __name__ == "__main__":
    sys.exit(main())
