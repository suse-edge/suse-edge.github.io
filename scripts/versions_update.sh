#!/usr/bin/env bash



set -eux

RELEASE_BRANCH=${RELEASE_BRANCH_:-"main"}

echo "Downloading release manifest for ${RELEASE_BRANCH} branch"
curl "https://src.opensuse.org/suse-edge/Factory/raw/branch/${RELEASE_BRANCH}/release-manifest-image/release_manifest.yaml" -o _release_manifest.yaml

# Uses https://github.com/mattrobenolt/jinja2-cli - on mac `brew install jinja2-cli`
VERSIONS_TEMPLATE=${VERSIONS_TEMPLATE:-"../asciidoc/edge-book/versions.adoc.j2"}
VERSIONS_FILE=${VERSIONS_FILE:-"../asciidoc/edge-book/versions.adoc"}
# Generating ${VERSIONS_FILE}
jinja2 ${VERSIONS_TEMPLATE} _release_manifest.yaml | tee ${VERSIONS_FILE}
REVISION_DATE=$(date +%Y-%m-%d)
sed -i "s/%%REVDATE%%/${REVISION_DATE}/" ${VERSIONS_FILE}
