#!/bin/bash
EA_EXT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export EA_EXT_DIR
# Wrapper to open URLs in Firefox Flatpak for EA OAuth login.
# maxima-cli calls $BROWSER <url>, but flatpak needs multiple args.
exec flatpak run org.mozilla.firefox "$@"
