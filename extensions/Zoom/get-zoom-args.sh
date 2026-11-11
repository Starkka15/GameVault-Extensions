#!/usr/bin/env bash
ZOOM_EXT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export ZOOM_EXT_DIR
PLATFORM=Zoom
export DECKY_PLUGIN_RUNTIME_DIR="${HOME}/homebrew/data/GameVault"
export DECKY_PLUGIN_DIR="${HOME}/homebrew/plugins/GameVault"
export DECKY_PLUGIN_LOG_DIR="${HOME}/homebrew/logs/GameVault"

export PYTHONPATH="${ZOOM_EXT_DIR}/":"${DECKY_PLUGIN_DIR}/scripts/":"${DECKY_PLUGIN_DIR}/scripts/shared/":$PYTHONPATH

export WORKING_DIR=$DECKY_PLUGIN_DIR

source "${ZOOM_EXT_DIR}/settings.sh"

ARGS=$($ZOOMCONF --get-args "${1}" --dbfile $DBFILE)
echo $ARGS
