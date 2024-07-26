#!/usr/bin/env bash

./create_po4a.sh asciidoc/edge-book/edge.adoc
po4a -v --srcdir $(pwd) --destdir $(pwd) -k 0 -M utf-8 -L utf-8 --no-translations -o nolinting edge_po4a.cfg
for lang in ja ko zh_CN; do mkdir -p asciidoc/l10n-weblate/$lang; gcp -axu asciidoc/images/ asciidoc/l10n-weblate/$lang; done
