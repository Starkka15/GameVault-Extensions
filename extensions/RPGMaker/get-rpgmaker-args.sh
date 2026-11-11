#!/usr/bin/env bash
RPGMAKER_EXT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export RPGMAKER_EXT_DIR
PLATFORM=RPGMaker
export DECKY_PLUGIN_RUNTIME_DIR="${DECKY_PLUGIN_RUNTIME_DIR:-${HOME}/homebrew/data/GameVault}"
export DECKY_PLUGIN_DIR="${DECKY_PLUGIN_DIR:-${HOME}/homebrew/plugins/GameVault}"
export DECKY_PLUGIN_LOG_DIR="${DECKY_PLUGIN_LOG_DIR:-${HOME}/homebrew/logs/GameVault}"

export PYTHONPATH="${RPGMAKER_EXT_DIR}/":"${DECKY_PLUGIN_DIR}/scripts/":"${DECKY_PLUGIN_DIR}/scripts/shared/":$PYTHONPATH
export WORKING_DIR=$DECKY_PLUGIN_DIR
export Extensions="${Extensions:-Extensions}"

source "${RPGMAKER_EXT_DIR}/settings.sh"

# Returns the engine tag (mv|mz|vxace|xp|vx) stored in the Arguments column.
ARGS=$($RPGMAKERCONF --get-args "${1}" --dbfile $DBFILE)
echo $ARGS
