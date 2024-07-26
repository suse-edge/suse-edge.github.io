#!/bin/bash
#
# Copyright (C) 2024 SUSE Software Solutions Germany GmbH
#
# Author:
# Frank Sundermeyer <fsundermeyer at opensuse dot org>
#
# Needs to be run inside the git checkout that contains MAIN
#
# INPUT
# relative or absolute path to an ASCIIDoc MAIN file
#
# OUTPUT
# creates a po4a config file named $CFG_FILE in the
# root of the GitHub checkout

#
# IMPORTANT: Include filenames MUST NOT include spaces
#

# ---------
# Verbose error handling
#
function exit_on_error {
    echo -e "ERROR: ${1}" >&2
    exit 1;
}


function include_grep {
    # Recursively get include files from an asciidoc "main" file
    #
    # include statements always start at the begin of the line, no other
    # characters (incl. space) are allowed before it, so a grep for
    # /^include::/ seems to be a safe enough
    local f
    f=$(grep -E '^include::' "$@" 2>/dev/null | sed 's/.*::\([^\[]*\).*/\1/g'  2>/dev/null)

    if [[ -n $f ]]; then
        INCLUDES+=( $f )
        include_grep "$f"
    else
        return
    fi
}

function relpath {
    # get the path of the include files relative to REPO_DIR

    local tmp
    # paths extracted from the MAIN are relative to MAIN_DIR
    # first get the absolute path
    pushd "$MAIN_DIR" >/dev/null
    tmp=$(realpath "$FILE")
    popd >/dev/null
    # now get the path relative to REPO_DIR
    echo "${tmp/$REPO_DIR\//}"
    }

# Required argument:
# relative or absolute path to the adoc MAIN file

[[ -z $1 ]] && exit_on_error "Provide a path to the ASCIIDoc main file"


########################
# Adjustable variables #
########################

CFG_FILE="edge_po4a.cfg"

LANGUAGES=( "ja" "ko" "zh-CN" )
LANGUAGES_ID="[po4a_langs]"

L10NPATH="asciidoc/l10n-weblate/edge.pot \$lang:asciidoc/l10n-weblate/\$lang.po"
L10NPATH_ID="[po4a_paths]"

PO4A_ALIAS="adoc opt:\"-M UTF-8 -L UTF-8\""
PO4A_ALIAS_ID="[po4a_alias:adoc]"

PO4A_OPTS="opt:\"--porefs=counter \""
PO4A_OPTS_ID="[options]"

FILE_ID="[type: asciidoc]"

############################################
# Do not change variable assignments below #
############################################

# Paths
# -----

# Get repo root
REPO_DIR=$(git rev-parse --show-toplevel) || exit_on_error "This script needs to be executed in a git check out"

MAIN=$(realpath "$1")
[[ -f $MAIN ]] || exit_on_error "File $MAIN does not exist"
MAIN_DIR=$(dirname "$MAIN")

CFG_PATH=${REPO_DIR}/${CFG_FILE}


# Array with adoc files
# ---------------------

declare -a INCLUDES

########
# MAIN #
########

#get the list of include files
include_grep "$MAIN"

# write the config file
# ---------------------

# header
echo "$LANGUAGES_ID ${LANGUAGES[*]}
$L10NPATH_ID $L10NPATH
$PO4A_ALIAS_ID $PO4A_ALIAS
$PO4A_OPTS_ID $PO4A_OPTS" > "$CFG_PATH"

# file list
for FILE in "${INCLUDES[@]}"; do
    echo "$FILE_ID $(relpath "$FILE")"
done >> "$CFG_PATH"
