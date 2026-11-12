#!/usr/bin/env bash
OPTIMA_EXT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export OPTIMA_EXT_DIR

OPTIMA_BIN="${HOME}/.local/bin/optima-cli"
# The static-musl optima-cli is hosted on GameVault's `runtimes` release (same
# place as the mkxp-z / RTP runtimes). It's statically linked, so it runs on
# SteamOS regardless of the system glibc.
OPTIMA_URL="https://github.com/Starkka15/GameVault/releases/download/runtimes/optima-cli-linux-x86_64"
# Testing a build before it is published: put a URL or a local file path in this
# file and it is used instead (same idea as GameVault's extensions-catalog file).
OPTIMA_SOURCE_OVERRIDE="${HOME}/homebrew/data/GameVault/optima-cli-source"

# ~/.local/bin/open-browser (the Firefox wrapper older versions installed for the
# self-signed login page) is left alone: the EA extension installs and uses the
# same file for its own login.

function uninstall() {
    echo "Uninstalling Ubisoft Connect (Optima) dependencies"
    rm -f "${OPTIMA_BIN}" 2>/dev/null
    echo "Removed optima-cli"
}

function fetch_optima() {
    local src="${OPTIMA_URL}"
    if [[ -s "${OPTIMA_SOURCE_OVERRIDE}" ]]; then
        src="$(head -n1 "${OPTIMA_SOURCE_OVERRIDE}")"
        echo "Using optima-cli from ${src} (test override)"
    fi
    if [[ "${src}" == http* ]]; then
        curl -sL -o "${OPTIMA_BIN}.tmp" "${src}" 2>/dev/null
    else
        cp "${src}" "${OPTIMA_BIN}.tmp" 2>/dev/null
    fi
}

function install() {
    echo "Installing Ubisoft Connect (Optima) dependencies"
    mkdir -p "${HOME}/.local/bin"

    # Download optima-cli (always update to latest)
    echo "Downloading optima-cli..."
    if fetch_optima && [[ -s "${OPTIMA_BIN}.tmp" ]]; then
        if file "${OPTIMA_BIN}.tmp" | grep -q "ELF"; then
            mv "${OPTIMA_BIN}.tmp" "${OPTIMA_BIN}"
            chmod +x "${OPTIMA_BIN}"
            echo "optima-cli installed: $("${OPTIMA_BIN}" --version 2>/dev/null)"
        else
            rm -f "${OPTIMA_BIN}.tmp"
            echo "Downloaded file is not a valid binary"
        fi
    else
        rm -f "${OPTIMA_BIN}.tmp" 2>/dev/null
        echo "Download failed"
    fi

    if [[ -f "${OPTIMA_BIN}" ]]; then
        echo "optima-cli: OK"
    else
        echo "optima-cli: NOT FOUND (Ubisoft Connect will not work)"
        echo "Manual install: download ${OPTIMA_URL} to ~/.local/bin/optima-cli and chmod +x it."
    fi
}

if [ "$1" == "uninstall" ]; then
    echo "Uninstalling dependencies: Ubisoft Connect (Optima) extension"
    uninstall
else
    echo "Installing dependencies: Ubisoft Connect (Optima) extension"
    install
fi
