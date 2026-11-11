#!/usr/bin/env bash
ZOOM_EXT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export ZOOM_EXT_DIR
ZOOMCONF="${ZOOM_EXT_DIR}/zoom-config.py"
export PYTHONPATH="${ZOOM_EXT_DIR}/":"${DECKY_PLUGIN_DIR}/scripts/":"${DECKY_PLUGIN_DIR}/scripts/shared/":$PYTHONPATH

export LAUNCHER="${ZOOM_EXT_DIR}/zoom-launcher.sh"
export ARGS_SCRIPT="${ZOOM_EXT_DIR}/get-zoom-args.sh"

# zoom-platform.sh does the actual install: it embeds innoextract and resolves
# the umu protonfix from the GUID inside the installer, so nothing here needs to
# know about Proton.
export ZOOM_INSTALLER="${DECKY_PLUGIN_RUNTIME_DIR}/zoom-platform.sh"

DBNAME="zoom.db"
DBFILE="${DECKY_PLUGIN_RUNTIME_DIR}/zoom.db"

if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/zoomtabconfig.json" ]]; then
    TEMP="${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/zoomtabconfig.json"
else
    TEMP="${ZOOM_EXT_DIR}/conf_schemas/zoomtabconfig.json"
fi
SETTINGS=$($ZOOMCONF --generate-env-settings-json $TEMP --dbfile $DBFILE 2>/dev/null) || true
eval "${SETTINGS}" 2>/dev/null || true

if [[ "${ZOOM_INSTALLLOCATION}" == "SSD" ]]; then
    INSTALL_DIR="${HOME}/Games/zoom/"
elif [[ "${ZOOM_INSTALLLOCATION}" == "MicroSD" ]]; then
    NVME=$(lsblk --list | grep nvme0n1\ |awk '{ print $2}' |  awk '{split($0, a,":"); print a[1]}')
    LINK=$(find /run/media -maxdepth 1  -type l )
    LINK_TARGET=$(readlink -f "${LINK}")
    MOUNT_POINT=$(lsblk --list --exclude "${NVME}" | grep part |  sed -n 's/.*part //p')
    if [[ "${MOUNT_POINT}" == "${LINK_TARGET}" ]]; then
        INSTALL_DIR="${LINK}/Games/zoom/"
    else
        INSTALL_DIR="/run/media/mmcblk0p1/Games/zoom/"
    fi
else
    INSTALL_DIR="${HOME}/Games/zoom/"
fi

if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/zoom_overrides.sh" ]]; then
   source "${DECKY_PLUGIN_RUNTIME_DIR}/zoom_overrides.sh"
fi

export INSTALL_DIR
