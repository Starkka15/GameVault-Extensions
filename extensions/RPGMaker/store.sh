#!/usr/bin/env bash
RPGMAKER_EXT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
export RPGMAKER_EXT_DIR

# Register RPGMaker as a platform with the gamevault.sh script
PLATFORMS+=("RPGMaker")
ACTIONS+=("purge")

# only source the settings if the platform is RPGMaker - avoids conflicts with other plugins
if [[ "${PLATFORM}" == "RPGMaker" ]]; then
    source "${RPGMAKER_EXT_DIR}/settings.sh"
fi

function RPGMaker_init() {
    $RPGMAKERCONF --list --dbfile "$DBFILE" &> /dev/null
}

function RPGMaker_refresh() {
    RPGMaker_init
    echo "{\"Type\": \"RefreshContent\", \"Content\": {\"Message\": \"Refreshed\"}}"
}

function RPGMaker_getgames(){
    FILTER="${1:-}"
    INSTALLED="${2:-false}"
    LIMIT="${3:-true}"
    IMAGE_PATH=""
    TEMP=$($RPGMAKERCONF --getgameswithimages "${IMAGE_PATH}" "${FILTER}" "${INSTALLED}" "${LIMIT}" "true" --dbfile "$DBFILE")
    # First run / empty DB: scan the folder then re-query.
    if echo "$TEMP" | jq -e '.Content.Games | length == 0' &>/dev/null; then
        if [[ $FILTER == "" ]] && [[ $INSTALLED == "false" ]]; then
            RPGMaker_init
            TEMP=$($RPGMAKERCONF --getgameswithimages "${IMAGE_PATH}" "${FILTER}" "${INSTALLED}" "${LIMIT}" "true" --dbfile "$DBFILE")
        fi
    fi
    echo "$TEMP"
}

function RPGMaker_getgamedetails(){
    TEMP=$($RPGMAKERCONF --getgamedata "${1}" "" --dbfile "$DBFILE" --forkname "" --version "" --platform "linux")
    echo "$TEMP"
    exit 0
}

function RPGMaker_getjsonimages(){
    TEMP=$($RPGMAKERCONF --get-base64-images "${1}" --dbfile "$DBFILE" --offline)
    echo "$TEMP"
}

function RPGMaker_getgamesize(){
    TEMP=$($RPGMAKERCONF --get-game-size "${1}" "${2}" --dbfile "$DBFILE")
    echo "$TEMP"
}

# Games are copied in by the user, so "download" is instant/no-op. The install queue
# (installQueue.ts) requires a Download that returns Type "Progress" and a GetProgress
# that reaches Percentage 100 before it will create the Steam shortcut.
function RPGMaker_download(){
    echo "{\"Type\": \"Progress\", \"Content\": {\"Message\": \"Ready\"}}"
}

function RPGMaker_getprogress(){
    echo "{\"Type\": \"ProgressUpdate\", \"Content\": {\"Percentage\": 100, \"Description\": \"Ready\"}}"
}

function RPGMaker_cancelinstall(){
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"${1} cancelled\"}}"
}

# "Install" = create the Steam shortcut for an already-present game (no download).
function RPGMaker_install(){
    RESULT=$($RPGMAKERCONF --addsteamclientid "${1}" "${2}" --dbfile "$DBFILE")
    ARGS=$($ARGS_SCRIPT "${1}")
    TEMP=$($RPGMAKERCONF --launchoptions "${1}" "${ARGS}" "" --dbfile "$DBFILE")
    echo "$TEMP"
    exit 0
}

function RPGMaker_getlaunchoptions(){
    ARGS=$($ARGS_SCRIPT "${1}")
    TEMP=$($RPGMAKERCONF --launchoptions "${1}" "${ARGS}" "" --dbfile "$DBFILE")
    echo "$TEMP"
    exit 0
}

# "Uninstall" = remove the Steam shortcut only. NEVER delete the user's game folder.
function RPGMaker_uninstall(){
    TEMP=$($RPGMAKERCONF --clearsteamclientid "${1}" --dbfile "$DBFILE")
    echo "$TEMP"
}

function RPGMaker_loginstatus(){
    TEMP=$($RPGMAKERCONF --getloginstatus --dbfile "$DBFILE")
    echo "$TEMP"
}

function RPGMaker_getsetting(){
    TEMP=$($RPGMAKERCONF --getsetting "$1" --dbfile "$DBFILE")
    echo "$TEMP"
}

function RPGMaker_savesetting(){
    $RPGMAKERCONF --savesetting "$1" "$2" --dbfile "$DBFILE"
}

function RPGMaker_gettabconfig(){
    if [[ ! -d "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas" ]]; then
        mkdir -p "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas"
    fi
    if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/rpgmakertabconfig.json" ]]; then
        TEMP=$(cat "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/rpgmakertabconfig.json")
    else
        TEMP=$(cat "${RPGMAKER_EXT_DIR}/conf_schemas/rpgmakertabconfig.json")
    fi
    SGDB_KEY=""
    if [[ -f "${DECKY_PLUGIN_RUNTIME_DIR}/steamgriddb_api_key" ]]; then
        SGDB_KEY=$(cat "${DECKY_PLUGIN_RUNTIME_DIR}/steamgriddb_api_key")
    fi
    TEMP=$(echo "$TEMP" | jq --arg key "$SGDB_KEY" \
      '(.Sections[] | select(.Name=="SteamGridDB") .Options[] | select(.Key=="SteamGridDBApiKey")).Value = $key')
    echo "{\"Type\":\"IniContent\", \"Content\": ${TEMP}}"
}

function RPGMaker_savetabconfig(){
    CONFIG=$(cat)
    echo "$CONFIG" > "${DECKY_PLUGIN_RUNTIME_DIR}/conf_schemas/rpgmakertabconfig.json"
    SGDB_KEY=$(echo "$CONFIG" | jq -r '.Sections[] | select(.Name=="SteamGridDB") | .Options[] | select(.Key=="SteamGridDBApiKey") | .Value // empty')
    if [[ -n "$SGDB_KEY" ]]; then
        echo "$SGDB_KEY" > "${DECKY_PLUGIN_RUNTIME_DIR}/steamgriddb_api_key"
    fi
    echo "{\"Type\": \"Success\", \"Content\": {\"Message\": \"RPG Maker tab config saved\"}}"
}

# Remove -> Everything: after Uninstall has dropped the shortcuts, delete the game
# folders themselves (never the drop folder, the home dir, or anything above them).
function RPGMaker_purge(){
    python3 - "$DBFILE" "${INSTALL_DIR}" <<'PY'
import json, os, shutil, sqlite3, sys
db, root = sys.argv[1], os.path.realpath(sys.argv[2])
home = os.path.realpath(os.path.expanduser("~"))
rows = []
if os.path.isfile(db):
    conn = sqlite3.connect(db)
    rows = conn.execute("SELECT RootFolder FROM Game").fetchall()
    conn.close()
removed, errors = 0, []
for (d,) in rows:
    if not d:
        continue
    p = os.path.realpath(d)
    if p in ("/", home, root) or root.startswith(p + os.sep) or home.startswith(p + os.sep):
        continue
    if not os.path.isdir(p):
        continue
    try:
        shutil.rmtree(p)
        removed += 1
    except OSError as e:
        errors.append(f"{d}: {e}")
msg = f"removed {removed} game folder(s)" + ("; " + "; ".join(errors[:3]) if errors else "")
print(json.dumps({"Type": "Error" if errors else "Success", "Content": {"Message": msg}}))
PY
}
