#!/usr/bin/env python3
"""Generate SUSE Edge documentation updates for a z-stream release.

The release manifest container is the source of truth. The script consumes the
three files shipped in that container:

* release_manifest.yaml
* release_images.yaml
* tooling_manifest.yaml

It updates version attributes, known air-gap image examples, and an
already-created release-note component table. Narrative release notes,
lifecycle dates, CVEs, and image-list additions/removals remain manual review
items.
"""

from __future__ import annotations

import argparse
import difflib
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any, Callable
from urllib.parse import urljoin
from urllib.request import urlopen

try:
    import yaml
except ImportError:  # pragma: no cover - only exercised when dependency is missing
    print(
        "error: this script requires PyYAML. Install it with "
        "'python3 -m pip install PyYAML'.",
        file=sys.stderr,
    )
    sys.exit(2)


REQUIRED_MANIFEST_FILES = (
    "release_manifest.yaml",
    "release_images.yaml",
    "tooling_manifest.yaml",
)

AIRGAP_DOCUMENTS = (
    "asciidoc/components/longhorn.adoc",
    "asciidoc/guides/air-gapped-eib-deployments.adoc",
    "asciidoc/product/atip-automated-provision.adoc",
    "asciidoc/product/atip-management-cluster.adoc",
)


@dataclass(frozen=True)
class ChartInfo:
    release_name: str
    chart: str
    version: str


@dataclass(frozen=True)
class ReleaseData:
    release_version: str
    release_family: str
    rke2_version: str
    k3s_version: str
    operating_system_version: str
    charts: dict[str, ChartInfo]
    images_by_repository: dict[str, tuple[str, ...]]
    attributes: dict[str, str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate SUSE Edge z-stream documentation updates from release manifest data."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        "--container-image",
        help=(
            "Release manifest image, for example "
            "registry.opensuse.org/isv/suse/edge/3.6/test_manifest_images/3.6/"
            "release-manifest:3.6.1."
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
        help="Factory Git ref containing release-manifest-image, for example upstream/3.6.",
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
        help="Do not pull a missing --container-image.",
    )
    parser.add_argument(
        "--release-date",
        type=iso_date,
        help="Release date in YYYY-MM-DD form. Updates revdate attributes when supplied.",
    )
    parser.add_argument(
        "--show-diff",
        action="store_true",
        help="Print unified diffs for generated changes.",
    )
    return parser.parse_args()


def iso_date(value: str) -> str:
    try:
        parsed = date.fromisoformat(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("expected a date in YYYY-MM-DD form") from exc
    return parsed.isoformat()


def load_yaml(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def find_container_engine(requested: str | None) -> str:
    candidates = [requested] if requested else ["podman", "docker"]
    for candidate in candidates:
        if candidate and shutil.which(candidate):
            return candidate
    raise RuntimeError(f"could not find container engine: {requested or 'podman or docker'}")


def ensure_container_image(image: str, engine: str, skip_pull: bool) -> None:
    if not skip_pull:
        print(f"Pulling release manifest image: {image}", file=sys.stderr)
        subprocess.check_call([engine, "pull", image])
        return

    if subprocess.call(
        [engine, "image", "inspect", image],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ) != 0:
        raise RuntimeError(f"container image is not available locally: {image}")


def extract_manifest_container(
    image: str, requested_engine: str | None, skip_pull: bool
) -> tempfile.TemporaryDirectory[str]:
    temp_dir = tempfile.TemporaryDirectory(prefix="edge-docs-release-manifest-")
    engine = find_container_engine(requested_engine)
    container_id = ""
    try:
        ensure_container_image(image, engine, skip_pull)
        container_id = subprocess.check_output(
            [engine, "create", image], text=True, stderr=subprocess.STDOUT
        ).strip()
        for filename in REQUIRED_MANIFEST_FILES:
            subprocess.check_call(
                [engine, "cp", f"{container_id}:/{filename}", str(Path(temp_dir.name) / filename)]
            )
    except subprocess.CalledProcessError as exc:
        temp_dir.cleanup()
        output = exc.output.strip() if isinstance(exc.output, str) else str(exc)
        raise RuntimeError(f"failed to extract release manifest files from {image}: {output}") from exc
    finally:
        if container_id:
            subprocess.call(
                [engine, "rm", "-f", container_id],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
    return temp_dir


def validate_manifest_dir(manifest_dir: Path) -> Path:
    missing = [name for name in REQUIRED_MANIFEST_FILES if not (manifest_dir / name).is_file()]
    if missing:
        raise RuntimeError(f"{manifest_dir} is missing required file(s): {', '.join(missing)}")
    return manifest_dir


def extract_manifest_url(release_manifest_url: str) -> tempfile.TemporaryDirectory[str]:
    if not release_manifest_url.endswith("/release_manifest.yaml"):
        raise RuntimeError("--manifest-url must point to a raw release_manifest.yaml file")

    temp_dir = tempfile.TemporaryDirectory(prefix="edge-docs-release-manifest-url-")
    base_url = release_manifest_url.rsplit("/", 1)[0] + "/"
    try:
        for filename in REQUIRED_MANIFEST_FILES:
            destination = Path(temp_dir.name) / filename
            with urlopen(urljoin(base_url, filename)) as response:
                destination.write_bytes(response.read())
    except OSError as exc:
        temp_dir.cleanup()
        raise RuntimeError(f"failed to download release manifest files from {base_url}: {exc}") from exc
    validate_manifest_dir(Path(temp_dir.name))
    return temp_dir


def extract_factory_ref(factory_repo: Path, factory_ref: str) -> tempfile.TemporaryDirectory[str]:
    if not factory_repo.is_dir():
        raise RuntimeError(f"Factory repository does not exist: {factory_repo}")

    temp_dir = tempfile.TemporaryDirectory(prefix="edge-docs-factory-manifest-")
    archive_path = Path(temp_dir.name) / "release-manifest-image.tar"
    try:
        subprocess.check_call(
            [
                "git",
                "-C",
                str(factory_repo),
                "archive",
                "--format=tar",
                "--output",
                str(archive_path),
                factory_ref,
                "release-manifest-image",
            ]
        )
        with tarfile.open(archive_path) as archive:
            archive.extractall(temp_dir.name)
        validate_manifest_dir(Path(temp_dir.name) / "release-manifest-image")
    except subprocess.CalledProcessError as exc:
        temp_dir.cleanup()
        raise RuntimeError(
            f"failed to archive release-manifest-image from {factory_repo} at {factory_ref}"
        ) from exc
    except (tarfile.TarError, RuntimeError) as exc:
        temp_dir.cleanup()
        raise RuntimeError(
            f"failed to extract release-manifest-image from {factory_repo} at {factory_ref}: {exc}"
        ) from exc
    return temp_dir


def chart_major_for(release_family: str) -> str:
    major, minor = release_family.split(".", 1)
    return str(int(major) * 100 + int(minor))


def substitution_context(release_family: str) -> dict[str, str]:
    return {
        "%%IMG_REPO%%": "registry.suse.com",
        "%%MANIFEST_REPO%%": "registry.suse.com",
        "%%IMG_PREFIX%%": f"edge/{release_family}/",
        "%%CHART_REPO%%": "oci://registry.suse.com",
        "%%CHART_PREFIX%%": "edge/charts/",
        "%%CHART_MAJOR%%": chart_major_for(release_family),
    }


def substitute_placeholders(value: str, context: dict[str, str]) -> str:
    result = value
    for placeholder, replacement in context.items():
        result = result.replace(placeholder, replacement)
    return result


def release_version_from_manifest(release_manifest: dict[str, Any]) -> str:
    spec_version = release_manifest.get("spec", {}).get("releaseVersion")
    metadata_name = str(release_manifest.get("metadata", {}).get("name", ""))
    metadata_match = re.fullmatch(r"release-manifest-(\d+)-(\d+)-(\d+)", metadata_name)
    metadata_version = ".".join(metadata_match.groups()) if metadata_match else None

    if spec_version is None and metadata_version is None:
        raise RuntimeError("cannot determine release version from spec.releaseVersion or metadata.name")
    if spec_version is None:
        return str(metadata_version)

    spec_version = str(spec_version)
    if metadata_version and metadata_version != spec_version:
        raise RuntimeError(
            f"release version mismatch: spec.releaseVersion is {spec_version}, "
            f"but metadata.name implies {metadata_version}"
        )
    if not re.fullmatch(r"\d+\.\d+\.\d+", spec_version):
        raise RuntimeError(f"unsupported release version: {spec_version}")
    return spec_version


def flatten_charts(workloads: list[dict[str, Any]], context: dict[str, str]) -> dict[str, ChartInfo]:
    charts: dict[str, ChartInfo] = {}

    def add(raw: dict[str, Any]) -> None:
        release_name = str(raw.get("releaseName", "")).strip()
        chart = substitute_placeholders(str(raw.get("chart", "")).strip(), context)
        version = substitute_placeholders(str(raw.get("version", "")).strip(), context)
        if release_name and version:
            charts[release_name] = ChartInfo(release_name, chart, version)

    for workload in workloads:
        add(workload)
        for key in ("dependencyCharts", "addonCharts"):
            for child in workload.get(key, []) or []:
                add(child)
    return charts


def parse_image_reference(reference: str) -> tuple[str, str] | None:
    reference = reference.strip().strip('"').strip("'")
    if "@" in reference:
        return None
    slash = reference.rfind("/")
    colon = reference.rfind(":")
    if colon <= slash:
        return None
    return reference[:colon], reference[colon + 1 :]


def parse_release_images(path: Path, context: dict[str, str]) -> dict[str, tuple[str, ...]]:
    images: dict[str, list[str]] = {}
    pattern = re.compile(r"^\s*-\s*name:\s*(.+?)\s*$")
    with path.open("r", encoding="utf-8") as handle:
        references = [match.group(1) for line in handle if (match := pattern.match(line))]

    for raw_reference in references:
        reference = substitute_placeholders(raw_reference.strip().strip('"').strip("'"), context)
        parts = parse_image_reference(reference)
        if not parts:
            continue
        repository, tag = parts
        images.setdefault(repository, [])
        if tag not in images[repository]:
            images[repository].append(tag)
    return {repository: tuple(tags) for repository, tags in images.items()}


def chart_version(charts: dict[str, ChartInfo], release_name: str) -> str | None:
    chart = charts.get(release_name)
    return chart.version if chart else None


def upstream_chart_version(version: str | None) -> str | None:
    if not version:
        return None
    return version.split("+up", 1)[1] if "+up" in version else version


def image_tag_by_basename(
    images: dict[str, tuple[str, ...]], basename: str
) -> str | None:
    tags = {
        tag
        for repository, repository_tags in images.items()
        if repository.rsplit("/", 1)[-1] == basename
        for tag in repository_tags
    }
    return next(iter(tags)) if len(tags) == 1 else None


def candidate_tags_for_repository(
    images: dict[str, tuple[str, ...]], repository: str
) -> tuple[str, ...]:
    exact = images.get(repository)
    if exact:
        return exact

    basename = repository.rsplit("/", 1)[-1]
    tags = {
        tag
        for candidate_repository, candidate_tags in images.items()
        if candidate_repository.rsplit("/", 1)[-1] == basename
        for tag in candidate_tags
    }
    return tuple(sorted(tags))


def semantic_version_from_tag(tag: str | None) -> str | None:
    if not tag:
        return None
    match = re.match(r"^v?(\d+\.\d+(?:\.\d+)?)", tag)
    return match.group(1) if match else None


def add_attribute(attributes: dict[str, str], name: str, value: str | None) -> None:
    if value:
        attributes[name] = value


def build_release_data(manifest_dir: Path) -> ReleaseData:
    release_manifest = load_yaml(manifest_dir / "release_manifest.yaml") or {}
    tooling_manifest = load_yaml(manifest_dir / "tooling_manifest.yaml") or {}
    release_version = release_version_from_manifest(release_manifest)
    release_family = ".".join(release_version.split(".")[:2])
    context = substitution_context(release_family)
    components = release_manifest.get("spec", {}).get("components", {})
    kubernetes = components.get("kubernetes", {})
    rke2_version = str(kubernetes.get("rke2", {}).get("version", ""))
    k3s_version = str(kubernetes.get("k3s", {}).get("version", ""))
    operating_system_version = str(components.get("operatingSystem", {}).get("version", ""))
    if not rke2_version or not k3s_version or not operating_system_version:
        raise RuntimeError("release manifest is missing Kubernetes or operating-system versions")

    workloads = components.get("workloads", {}).get("helm", []) or []
    charts = flatten_charts(workloads, context)
    images = parse_release_images(manifest_dir / "release_images.yaml", context)

    rancher = chart_version(charts, "rancher")
    longhorn = upstream_chart_version(chart_version(charts, "longhorn"))
    cert_manager = upstream_chart_version(chart_version(charts, "cert-manager"))
    elemental = upstream_chart_version(chart_version(charts, "elemental-operator"))
    endpoint_copier = upstream_chart_version(chart_version(charts, "endpoint-copier-operator"))
    private_registry = upstream_chart_version(chart_version(charts, "private-registry-helm"))
    sriov = upstream_chart_version(chart_version(charts, "sriov-network-operator"))

    neuvector = semantic_version_from_tag(image_tag_by_basename(images, "neuvector-controller"))
    kubevirt = semantic_version_from_tag(image_tag_by_basename(images, "virt-operator"))
    cdi = semantic_version_from_tag(image_tag_by_basename(images, "cdi-operator"))
    suc_tag = image_tag_by_basename(images, "system-upgrade-controller")
    fleet_tag = image_tag_by_basename(images, "fleet")
    ipa_tag = image_tag_by_basename(images, "ironic-python-agent")
    capi_metal3_tag = image_tag_by_basename(images, "cluster-api-provider-metal3")

    eib_version = str(tooling_manifest.get("eib", {}).get("version", ""))
    kiwi_version = str(tooling_manifest.get("kiwi", {}).get("version", ""))
    eib_family_match = re.match(r"^(\d+\.\d+)", eib_version)

    attributes: dict[str, str] = {
        "version-edge-registry": release_family,
        "version-kubernetes-k3s": k3s_version,
        "version-kubernetes-rke2": rke2_version,
        "version-operatingsystem": operating_system_version,
        "release-tag-edge-charts": f"release-{release_family}",
        "release-tag-atip": f"release-{release_family}",
        "release-tag-telco-cloud": f"release-{release_family}",
        "release-tag-fleet-examples": f"release-{release_version}",
    }
    add_attribute(attributes, "version-eib", eib_version)
    add_attribute(attributes, "version-kiwi-builder", kiwi_version)
    add_attribute(
        attributes,
        "version-eib-api-latest",
        eib_family_match.group(1) if eib_family_match else None,
    )
    add_attribute(
        attributes,
        "release-tag-eib",
        f"release-{eib_family_match.group(1)}" if eib_family_match else None,
    )
    add_attribute(attributes, "version-rancher-prime", rancher)
    add_attribute(attributes, "version-rancher-chart", rancher)
    add_attribute(attributes, "release-tag-rancher", f"v{rancher}" if rancher else None)
    add_attribute(attributes, "version-cert-manager", cert_manager)
    add_attribute(attributes, "version-elemental-operator", elemental)
    add_attribute(attributes, "version-longhorn", longhorn)
    add_attribute(attributes, "version-longhorn-docs", longhorn)
    add_attribute(attributes, "version-neuvector", neuvector)
    add_attribute(attributes, "version-kubevirt", kubevirt)
    add_attribute(attributes, "version-kubevirt-release", f"v{kubevirt}" if kubevirt else None)
    add_attribute(attributes, "version-cdi", cdi)
    add_attribute(attributes, "version-endpoint-copier-operator", endpoint_copier)
    add_attribute(attributes, "version-suc", suc_tag)
    add_attribute(attributes, "version-fleet", fleet_tag)
    add_attribute(attributes, "version-private-registry", private_registry)
    add_attribute(attributes, "version-ipa", semantic_version_from_tag(ipa_tag))
    add_attribute(attributes, "version-capi-provider-metal3", f"v1beta1@{capi_metal3_tag}" if capi_metal3_tag else None,)
    add_attribute(attributes, "version-sriov-upstream", sriov)

    chart_attributes = {
        "version-cdi-chart": "cdi",
        "version-elemental-operator-chart": "elemental-operator",
        "version-elemental-operator-crds-chart": "elemental-operator-crds",
        "version-elemental-dashboard-extension-chart": "elemental",
        "version-endpoint-copier-operator-chart": "endpoint-copier-operator",
        "version-kubevirt-chart": "kubevirt",
        "version-kubevirt-dashboard-extension-chart": "kubevirt-dashboard-extension",
        "version-longhorn-chart": "longhorn",
        "version-longhorn-crd-chart": "longhorn-crd",
        "version-metal3-chart": "metal3",
        "version-metallb-chart": "metallb",
        "version-neuvector-chart": "neuvector",
        "version-neuvector-crd-chart": "neuvector-crd",
        "version-neuvector-dashboard-extension-chart": "neuvector-ui-ext",
        "version-rancher-turtles-chart": "rancher-turtles-providers",
        "version-rancher-turtles-providers-chart": "rancher-turtles-providers",
        "version-sriov-crd-chart": "sriov-crd",
        "version-sriov-network-operator-chart": "sriov-network-operator",
        "version-upgrade-controller-chart": "upgrade-controller",
        "version-akri-chart": "akri",
        "version-akri-dashboard-extension-chart": "akri-dashboard-extension",
    }
    for attribute, release_name in chart_attributes.items():
        add_attribute(attributes, attribute, chart_version(charts, release_name))

    return ReleaseData(
        release_version=release_version,
        release_family=release_family,
        rke2_version=rke2_version,
        k3s_version=k3s_version,
        operating_system_version=operating_system_version,
        charts=charts,
        images_by_repository=images,
        attributes=attributes,
    )


def replace_asciidoc_attribute(text: str, name: str, value: str) -> str:
    pattern = re.compile(rf"^(:{re.escape(name)}:\s*)(\S+)(\s*)$", re.MULTILINE)
    match = pattern.search(text)
    if not match:
        return text

    current = match.group(2)
    if name == "version-edge":
        current_parts = current.split(".")
        value = value if len(current_parts) >= 3 else ".".join(value.split(".")[:2])
    elif name in {"version-suc", "version-fleet"}:
        value = value.lstrip("v") if not current.startswith("v") else f"v{value.lstrip('v')}"

    return pattern.sub(rf"\g<1>{value}\g<3>", text, count=1)


def update_versions_adoc(
    text: str, release: ReleaseData, release_date: str | None, source_label: str
) -> str:
    updated = text
    attributes = dict(release.attributes)
    attributes["version-edge"] = release.release_version
    if release_date:
        attributes["revdate"] = release_date

    for name, value in attributes.items():
        updated = replace_asciidoc_attribute(updated, name, value)

    if re.search(r"^// Source: .+$", updated, flags=re.MULTILINE):
        updated = re.sub(
            r"^// Source: .+$", f"// Source: {source_label}", updated, count=1, flags=re.MULTILINE
        )
    else:
        lines = updated.splitlines(keepends=True)
        insert_at = 1 if lines and lines[0].startswith("// NOTE - Generated") else 0
        lines.insert(insert_at, f"// Source: {source_label}\n")
        updated = "".join(lines)
    return updated


IMAGE_LIST_LINE = re.compile(r"^(\s*-\s+name:\s+)(\S+)(\s*)$", re.MULTILINE)


def update_airgap_images(text: str, release: ReleaseData) -> str:
    current_tags_by_repository: dict[str, set[str]] = {}
    for match in IMAGE_LIST_LINE.finditer(text):
        parts = parse_image_reference(match.group(2))
        if parts:
            repository, tag = parts
            current_tags_by_repository.setdefault(repository, set()).add(tag)

    def replace(match: re.Match[str]) -> str:
        if "{" in match.group(2) or "}" in match.group(2):
            return match.group(0)
        parts = parse_image_reference(match.group(2))
        if not parts:
            return match.group(0)
        repository, current_tag = parts
        current_repository_tags = current_tags_by_repository.get(repository, set())
        if len(current_repository_tags) > 1:
            return match.group(0)
        candidates = candidate_tags_for_repository(
            release.images_by_repository, repository
        )
        if not candidates or current_tag in candidates or len(candidates) != 1:
            return match.group(0)
        target_tag = candidates[0]
        if target_tag in current_repository_tags:
            return match.group(0)
        return f"{match.group(1)}{repository}:{target_tag}{match.group(3)}"

    return IMAGE_LIST_LINE.sub(replace, text)


def artifact_versions(release: ReleaseData) -> dict[str, tuple[str, ...]]:
    artifacts = dict(release.images_by_repository)
    for chart in release.charts.values():
        repository = chart.chart.removeprefix("oci://")
        if not repository or "/" not in repository:
            continue
        current = list(artifacts.get(repository, ()))
        if chart.version not in current:
            current.append(chart.version)
        artifacts[repository] = tuple(current)
        if repository.startswith("registry.suse.com/edge/charts/"):
            chart_name = repository.rsplit("/", 1)[-1]
            docs_repository = (
                f"registry.suse.com/edge/{release.release_family}/{chart_name}-chart"
            )
            artifacts[docs_repository] = (chart.version,)
    return artifacts


INLINE_ARTIFACT = re.compile(
    r"(?P<repo>(?:[a-z0-9.-]+/)+(?:[A-Za-z0-9._{}-]+)):(?P<tag>[A-Za-z0-9.+_-]+)"
)


def update_inline_artifacts(text: str, release: ReleaseData) -> str:
    candidates_by_repo = artifact_versions(release)

    def replace(match: re.Match[str]) -> str:
        repository = match.group("repo")
        current_tag = match.group("tag")
        if "{" in repository or "}" in repository or "{" in current_tag or "}" in current_tag:
            return match.group(0)
        candidates = candidate_tags_for_repository(candidates_by_repo, repository)
        if not candidates or current_tag in candidates or len(candidates) != 1:
            return match.group(0)
        return f"{repository}:{candidates[0]}"

    return INLINE_ARTIFACT.sub(replace, text)


RELEASE_NOTE_ROWS: dict[str, tuple[str, str | None]] = {
    "K3s": ("k3s", "N/A"),
    "RKE2": ("rke2", "N/A"),
    "SUSE Rancher Prime": ("version-rancher-prime", "version-rancher-chart"),
    "SUSE Storage (Longhorn)": ("version-longhorn", "version-longhorn-chart"),
    "SUSE Security (NeuVector)": ("version-neuvector", "version-neuvector-chart"),
    "Rancher Turtles Providers (CAPI)": (
        "rancher-turtles-upstream",
        "version-rancher-turtles-providers-chart",
    ),
    "Metal^3^": ("metal3-upstream", "version-metal3-chart"),
    "MetalLB": ("metallb-upstream", "version-metallb-chart"),
    "Elemental": ("version-elemental-operator", "version-elemental-operator-chart"),
    "Elemental Dashboard Extension": (
        "elemental-dashboard-upstream",
        "version-elemental-dashboard-extension-chart",
    ),
    "Edge Image Builder": ("version-eib", "N/A"),
    "KubeVirt": ("version-kubevirt", "version-kubevirt-chart"),
    "KubeVirt Dashboard Extension": (
        "kubevirt-dashboard-upstream",
        "version-kubevirt-dashboard-extension-chart",
    ),
    "Containerized Data Importer (CDI)": ("version-cdi", "version-cdi-chart"),
    "Endpoint Copier Operator": (
        "version-endpoint-copier-operator",
        "version-endpoint-copier-operator-chart",
    ),
    "SR-IOV Network Operator": ("version-sriov-upstream", "version-sriov-network-operator-chart"),
    "System Upgrade Controller": ("version-suc", None),
    "Upgrade Controller": ("upgrade-controller-upstream", "version-upgrade-controller-chart"),
    "SUSE Private Registry": ("version-private-registry", "version-private-registry"),
    "Kiwi Builder": ("version-kiwi-builder", "N/A"),
    "Cert-Manager": ("version-cert-manager", "version-cert-manager"),
}


def release_note_value(release: ReleaseData, key: str) -> str | None:
    if key == "N/A":
        return "N/A"
    if key == "k3s":
        return semantic_version_from_tag(release.k3s_version)
    if key == "rke2":
        return semantic_version_from_tag(release.rke2_version)
    release_name_keys = {
        "rancher-turtles-upstream": "rancher-turtles-providers",
        "metal3-upstream": "metal3",
        "metallb-upstream": "metallb",
        "elemental-dashboard-upstream": "elemental",
        "kubevirt-dashboard-upstream": "kubevirt-dashboard-extension",
        "upgrade-controller-upstream": "upgrade-controller",
    }
    if key in release_name_keys:
        return upstream_chart_version(chart_version(release.charts, release_name_keys[key]))
    value = release.attributes.get(key)
    if key in {"version-suc", "version-fleet"} and value:
        return value.lstrip("v")
    return value


def update_release_note_rows(text: str, release: ReleaseData) -> str:
    for component, (version_key, chart_key) in RELEASE_NOTE_ROWS.items():
        pattern = re.compile(
            rf"^(?P<p1>s?\|)\s*{re.escape(component)}\s+"
            rf"(?P<p2>s?\|)\s*(?P<version>[^|]+?)\s+"
            rf"(?P<p3>s?\|)\s*(?P<chart>[^|]+?)\s+"
            rf"(?P<p4>s?\|)(?P<rest>.*)$",
            re.MULTILINE,
        )
        match = pattern.search(text)
        if not match:
            continue
        version = release_note_value(release, version_key)
        chart = (
            release_note_value(release, chart_key)
            if chart_key
            else match.group("chart").strip()
        )
        if not version:
            continue
        chart = chart or match.group("chart").strip()
        changed = version != match.group("version").strip() or chart != match.group("chart").strip()
        pipe = "s|" if changed else match.group("p1")
        replacement = f"{pipe} {component} {pipe} {version} {pipe} {chart} {pipe}{match.group('rest')}"
        text = pattern.sub(replacement, text, count=1)
    return text


def update_release_notes(
    text: str, release: ReleaseData, release_date: str | None
) -> tuple[str, bool]:
    anchor = f"[#release-notes-{release.release_version.replace('.', '-')}]"
    start = text.find(anchor)
    if start < 0:
        return text, False
    next_section = text.find("[#release-notes-", start + len(anchor))
    end = next_section if next_section >= 0 else len(text)
    section = text[start:end]
    section = update_release_note_rows(section, release)
    section = update_inline_artifacts(section, release)
    updated = text[:start] + section + text[end:]
    if release_date:
        updated = replace_asciidoc_attribute(updated, "revdate", release_date)
    return updated, True


def collect_updates(
    repo_root: Path,
    release: ReleaseData,
    release_date: str | None,
    source_label: str,
) -> tuple[dict[Path, str], list[str]]:
    updates: dict[Path, str] = {}
    notes: list[str] = []

    def update_file(relative: str, transform: Callable[[str], str]) -> None:
        path = repo_root / relative
        if not path.is_file():
            return
        old = path.read_text(encoding="utf-8")
        new = transform(old)
        if new != old:
            updates[path] = new

    update_file(
        "asciidoc/edge-book/versions.adoc",
        lambda text: update_versions_adoc(text, release, release_date, source_label),
    )
    for relative in AIRGAP_DOCUMENTS:
        update_file(relative, lambda text: update_airgap_images(text, release))

    release_notes_path = repo_root / "asciidoc/edge-book/releasenotes.adoc"
    if release_notes_path.is_file():
        old = release_notes_path.read_text(encoding="utf-8")
        new, found = update_release_notes(old, release, release_date)
        if new != old:
            updates[release_notes_path] = new
        if not found:
            notes.append(
                f"Create the release-notes-{release.release_version.replace('.', '-')} section manually; "
                "then rerun the script to update its component table and artifact references."
            )

    notes.extend(
        (
            "Review release-note prose, lifecycle dates, CVEs, known issues, and links manually.",
            "Review additions and removals in embeddedArtifactRegistry image examples manually; "
            "the script only updates unambiguous existing image repositories or image-name aliases.",
            "Review values not present in the release manifest container, including MLM, Nessie, "
            "Fleet chart, and System Upgrade Controller chart versions.",
        )
    )
    return updates, notes


def validate_repository_family(repo_root: Path, release: ReleaseData) -> None:
    versions_path = repo_root / "asciidoc/edge-book/versions.adoc"
    text = versions_path.read_text(encoding="utf-8")
    match = re.search(r"^:version-edge-registry:\s*(\S+)\s*$", text, flags=re.MULTILINE)
    if match and match.group(1) != release.release_family:
        raise RuntimeError(
            f"release manifest family {release.release_family} does not match this documentation "
            f"branch's version-edge-registry {match.group(1)}"
        )


def print_summary(
    updates: dict[Path, str], notes: list[str], repo_root: Path, show_diff: bool
) -> None:
    if updates:
        print(f"{len(updates)} file(s) would change:")
        for path in sorted(updates):
            print(f"  {path.relative_to(repo_root)}")
    else:
        print("No deterministic documentation updates needed.")

    if show_diff:
        for path in sorted(updates):
            old = path.read_text(encoding="utf-8").splitlines(keepends=True)
            new = updates[path].splitlines(keepends=True)
            sys.stdout.writelines(
                difflib.unified_diff(
                    old,
                    new,
                    fromfile=str(path.relative_to(repo_root)),
                    tofile=str(path.relative_to(repo_root)),
                )
            )

    print("Manual review checklist:")
    for note in notes:
        print(f"  - {note}")


def main() -> int:
    args = parse_args()
    repo_root = args.repo_root.resolve()
    if not (repo_root / "asciidoc/edge-book/versions.adoc").is_file():
        print(f"error: {repo_root} does not look like the documentation repository root", file=sys.stderr)
        return 2

    temp_dir: tempfile.TemporaryDirectory[str] | None = None
    try:
        if args.container_image:
            temp_dir = extract_manifest_container(
                args.container_image, args.container_engine, args.skip_pull
            )
            manifest_dir = Path(temp_dir.name)
            source_label = args.container_image
        elif args.manifest_url:
            temp_dir = extract_manifest_url(args.manifest_url)
            manifest_dir = Path(temp_dir.name)
            source_label = args.manifest_url
        elif args.factory_ref:
            if not args.factory_repo:
                raise RuntimeError("--factory-repo is required with --factory-ref")
            temp_dir = extract_factory_ref(args.factory_repo.resolve(), args.factory_ref)
            manifest_dir = Path(temp_dir.name) / "release-manifest-image"
            source_label = f"Factory {args.factory_ref}"
        else:
            manifest_dir = validate_manifest_dir(args.manifest_dir.resolve())
            source_label = str(manifest_dir)

        release = build_release_data(manifest_dir)
        validate_repository_family(repo_root, release)
        updates, notes = collect_updates(
            repo_root, release, args.release_date, source_label
        )
        print(
            f"Generated documentation updates for SUSE Edge {release.release_version} "
            f"(RKE2 {release.rke2_version}, K3s {release.k3s_version})."
        )
        print(f"Release manifest source: {source_label}")
        print_summary(
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
