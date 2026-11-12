#!/usr/bin/env bash
OPTIMA_EXT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export OPTIMA_EXT_DIR
# Runs as a Steam launch entry (from Optima_login) so it executes in a graphical
# session, in Game Mode too. Two sign-ins, one button:
#   1. optima-cli: opens Ubisoft's real login page in Steam's browser (the
#      overlay browser in Game Mode) and reads the session once you've signed
#      in; that session lists the library and authorizes downloads.
#   2. Ubisoft Connect: installed into its own prefix if missing (with a progress
#      window), then opened for its own sign-in. optima-cli closes it once the
#      login is saved. Connect does ownership, DRM and launch.
export DECKY_PLUGIN_RUNTIME_DIR="${HOME}/homebrew/data/GameVault"
export DECKY_PLUGIN_DIR="${HOME}/homebrew/plugins/GameVault"
export DECKY_PLUGIN_LOG_DIR="${HOME}/homebrew/logs/GameVault"
export WORKING_DIR=$DECKY_PLUGIN_DIR
export Extensions="Extensions"
ID=$1
echo $1
shift

source "${OPTIMA_EXT_DIR}/settings.sh"

mkdir -p "$DECKY_PLUGIN_LOG_DIR"
LOG="${DECKY_PLUGIN_LOG_DIR}/optimalogin.log"
echo "[$(date)] Starting Ubisoft login..." >> "$LOG"

# --steam opens the page and blocks until the sign-in is read (or the page is closed).
if $OPTIMA_CMD login --steam &>> "$LOG"; then
    echo "Optima login successful" >> "$LOG"
    source "${OPTIMA_EXT_DIR}/connect-setup.sh"
    optima_connect_setup "$LOG"
    if $OPTIMA_CMD connect signin &>> "$LOG"; then
        echo "Ubisoft Connect sign-in successful" >> "$LOG"
    else
        echo "Ubisoft Connect sign-in not finished; Connect will ask on the first game launch" >> "$LOG"
    fi
else
    echo "Login failed" >> "$LOG"
fi

"${DECKY_PLUGIN_DIR}/scripts/gamevault.sh" Optima loginstatus --flush-cache
