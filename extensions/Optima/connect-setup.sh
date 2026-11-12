#!/usr/bin/env bash
# Sourced by login.sh and optima-launcher.sh (after settings.sh).
#
# optima_connect_setup LOG: install the official Ubisoft Connect client into
# optima-cli's Connect prefix if it isn't there yet. The installer is ~260 MB and
# the first run sets up a Proton prefix, so this takes minutes; show a progress
# window (zenity, present on SteamOS) so Game Mode isn't a blank screen meanwhile.
# Without zenity it still runs, just without the window.
function optima_connect_setup() {
    local log="$1"
    [[ -f "${OPTIMA_CONNECT_EXE}" ]] && return 0
    echo "[$(date)] Installing Ubisoft Connect..." >> "$log"
    if command -v zenity &>/dev/null; then
        # zenity shows each output line as the status text and closes at EOF.
        "$OPTIMA_CMD" connect setup 2>&1 | tee -a "$log" \
            | sed -u 's/^/# /' \
            | zenity --progress --pulsate --auto-close --no-cancel \
                --title="Ubisoft Connect" --width=600 \
                --text="Installing the official Ubisoft Connect client (first time only)..." 2>/dev/null
        return "${PIPESTATUS[0]}"
    fi
    "$OPTIMA_CMD" connect setup >> "$log" 2>&1
}
