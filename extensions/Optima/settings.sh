#!/usr/bin/env bash
OPTIMA_EXT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export OPTIMA_EXT_DIR
OPTIMACONF="${OPTIMA_EXT_DIR}/optima-config.py"
export PYTHONPATH="${OPTIMA_EXT_DIR}/":"${DECKY_PLUGIN_DIR}/scripts/":"${DECKY_PLUGIN_DIR}/scripts/shared/":$PYTHONPATH

export LAUNCHER="${OPTIMA_EXT_DIR}/optima-launcher.sh"
export SETTINGS_LAUNCHER="${OPTIMA_EXT_DIR}/optima-settings-launcher.sh"
export ARGS_SCRIPT="${OPTIMA_EXT_DIR}/get-optima-args.sh"

DBNAME="optima.db"
DBFILE="${DECKY_PLUGIN_RUNTIME_DIR}/optima.db"

export OPTIMA_CMD="${HOME}/.local/bin/optima-cli"
export NO_COLOR=1
# optima-cli launches games through the official Ubisoft Connect client, which it
# installs into its own Proton prefix (~/.local/share/optima/connect-prefix).
OPTIMA_CONNECT_EXE="${HOME}/.local/share/optima/connect-prefix/drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/UbisoftConnect.exe"

if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/optimatabconfig.json" ]]; then
    TEMP="${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/optimatabconfig.json"
else
    TEMP="${OPTIMA_EXT_DIR}/conf_schemas/optimatabconfig.json"
fi
SETTINGS=$($OPTIMACONF --generate-env-settings-json $TEMP --dbfile $DBFILE 2>/dev/null) || true
eval "${SETTINGS}" 2>/dev/null || true

if [[ "${OPTIMA_INSTALLLOCATION}" == "SSD" ]]; then
    INSTALL_DIR="${HOME}/Games/optima/"
elif [[ "${OPTIMA_INSTALLLOCATION}" == "MicroSD" ]]; then
    NVME=$(lsblk --list | grep nvme0n1\ |awk '{ print $2}' |  awk '{split($0, a,":"); print a[1]}')
    LINK=$(find /run/media -maxdepth 1  -type l )
    LINK_TARGET=$(readlink -f "${LINK}")
    MOUNT_POINT=$(lsblk --list --exclude "${NVME}" | grep part |  sed -n 's/.*part //p')
    if [[ "${MOUNT_POINT}" == "${LINK_TARGET}" ]]; then
        INSTALL_DIR="${LINK}/Games/optima/"
    else
        INSTALL_DIR="/run/media/mmcblk0p1/Games/optima/"
    fi
else
    INSTALL_DIR="${HOME}/Games/optima/"
fi

# Optionally propagate a preferred Proton (e.g. UMU-Proton-9.0-4e) to optima-cli.
# Set OPTIMA_PROTON in optima_overrides.sh to pin a version per device.
if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/optima_overrides.sh" ]]; then
   source "${DECKY_PLUGIN_RUNTIME_DIR}/optima_overrides.sh"
fi

export INSTALL_DIR
