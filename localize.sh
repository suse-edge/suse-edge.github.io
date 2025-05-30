#!/usr/bin/env bash
# shellcheck disable=SC3009,SC3010,SC3030,SC3037,SC3043,SC3044,SC3054
#
# Copyright (C) 2024 SUSE Software Solutions Germany GmbH
#
# Author:
# Frank Sundermeyer <fsundermeyer at opensuse dot org>
#
# Create and operate a po4a workflow for the Edge documentation
#

LANGUAGES=( "ja" "ko" "zh-CN" )
DC_FILE="asciidoc/DC-edge"
PO4A_CONFIG="edge_po4a.cfg"
PO4A_DIR="l10n"

# ---------
# Verbose error handling
#
exit_on_error() {
    echo -e "ERROR: ${1}" >&2
    exit 1;
}

# Get repo root
REPO_ROOT=$(git rev-parse --show-toplevel) || \
    exit_on_error "This script needs to be executed from a git check out"

# Check Path to the DC-file
[[ -f ${REPO_ROOT}/$DC_FILE ]] || \
    exit_on_error "Cannot access ${REPO_ROOT}/$DCFILE.\nThe path to the DC-file must be relative to the repository root."

# Get project name
PRJ_NAME=${DC_FILE##*/DC-}

help() {
    cat << EOF_help
Usage: $(basename "$0") [option]
Only specify a single option (others are ignored).

Before you start, make sure the variables
LANGUAGES / DC_FILE / PO4A_DIR / PO4A_CONFIG
are correctly set in $(basename "$0").

Options:
  -h, --help                 Print this help

  -i, --init                 Initializes the po4a workflow:
                              - creates directory structure in ${PO4A_DIR}/
                              - creates the XML files
                              - creates the po4a config
                              - creates the .po/.pot files
                              - creates a DC-file for each langauge
                              - copies the images

  -p, --update-po            Updates the XML source file, the .pot and the
                             .po files.

  -t, --update-translation   Updates the source files for each language with
                             the latest translations from the po files
EOF_help
}


create_xml() {
    cp "$(daps -d "${REPO_ROOT}/$DC_FILE" profile)/${PRJ_NAME}.xml" "${PO4A_DIR}"/source
}


update_po() {
    cd "$REPO_ROOT" >/dev/null || exit_on_error "Cannot access $REPO_ROOT"
    # create and copy DopBook XML
    create_xml
    # update po files
    po4a --verbose --no-translations ${PO4A_CONFIG}
    cd - >/dev/null
}

update_translation() {
    cd "$REPO_ROOT" >/dev/null || exit_on_error "Cannot access $REPO_ROOT"
    # update translations
    po4a --verbose --no-update ${PO4A_CONFIG}
    cd - >/dev/null
}

init() {
    local lang img
    echo "Creating basic directories"
    mkdir -p "${REPO_ROOT}"/"${PO4A_DIR}"/{po,translated,source}
    # create and copy DopBook XML
    echo "Building xml file"
    create_xml
    for lang in "${LANGUAGES[@]}"; do
        echo -e "\nCreating directories for $lang"
        mkdir -p "${REPO_ROOT}"/"${PO4A_DIR}"/translated/"${lang}"/{images,xml}
        # write DC-file
        echo "Writing DC file for $lang"
        cat <<EOF_DC > "${REPO_ROOT}"/"${PO4A_DIR}"/translated/"${lang}"/DC-"${PRJ_NAME}"
MAIN=${PRJ_NAME}.xml
IMG_SRC_DIR=images
STYLEROOT="/usr/share/xml/docbook/stylesheet/suse2022-ns"
FALLBACK_STYLEROOT="/usr/share/xml/docbook/stylesheet/suse-ns"
DOCBOOK5_RNG_URI="http://docbook.org/xml/5.0/rng/docbookxi.rng"
EOF_DC
        # copy images
        echo "Copying images for $lang"
        for img in $(daps -d "${REPO_ROOT}/$DC_FILE" list-srcfiles --imgonly); do
            cp "$img" "${REPO_ROOT}/${PO4A_DIR}/translated/$lang/images/"
        done
    done
    echo
    # write po4a config
    echo "Writing po4a config"
    cat <<EOF_PO4A > "${REPO_ROOT}/${PO4A_CONFIG}"
[po4a_langs] ${LANGUAGES[*]}
[po4a_paths] ${PO4A_DIR}/po/edge.pot \$lang:${PO4A_DIR}/po/\$lang.po
[options] opt: --keep 0 --porefs=counter --master-charset UTF-8 --localized-charset UTF-8
[po4a_alias:docbook] docbook opt: -o nodefault="<screen>" -o break="<screen>" -o untranslated="<screen>"
[type: docbook] ${PO4A_DIR}/source/${PRJ_NAME}.xml  \$lang:${PO4A_DIR}/translated/\$lang/xml/${PRJ_NAME}.xml
EOF_PO4A
    update_po
}

CMD="$1"

if [[ -z "$CMD" ]]; then
    help
    exit 1
elif  [[ "--help" == "$CMD" || "-h" == "$CMD" ]]; then
    help
fi

case "$CMD" in
    -i|--init)
        init
        ;;
    -p|--update-po)
        update_po
        ;;
    -t|--update-translation)
        update_translation
        ;;
    *)
        help
        exit 1
        ;;
esac
