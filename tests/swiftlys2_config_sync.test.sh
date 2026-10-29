#!/bin/bash
# Exercises the swiftlys2.sh update copy rules against a fake archive + fake install.
# Asserts the three things that matter and are easy to get backwards in shell.
set -u

PASS=0; FAIL=0
check() { # name expected actual
    if [ "$2" = "$3" ]; then printf '  ok   %-52s %s\n' "$1" "$2"; PASS=$((PASS+1))
    else printf '  FAIL %-52s expected=%q actual=%q\n' "$1" "$2" "$3"; FAIL=$((FAIL+1)); fi
}

root=$(mktemp -d)
swiftly_dir="$root/archive"      # what the new release ships
target_dir="$root/installed"     # what the server already has

# --- new release ---------------------------------------------------------
mkdir -p "$swiftly_dir"/{bin,gamedata,configs/menus}
echo "NEW-BIN"                 > "$swiftly_dir/bin/swiftly.so"
echo "NEW-GAMEDATA"            > "$swiftly_dir/gamedata/offsets.json"
echo "NEW-CORE-DEFAULT"        > "$swiftly_dir/configs/core.jsonc"
echo "NEW-MENUS-EXAMPLE"       > "$swiftly_dir/configs/menus/menus.example.jsonc"
echo "NEW-FILE-THIS-RELEASE"   > "$swiftly_dir/configs/brandnew.jsonc"

# --- existing install, with operator edits -------------------------------
mkdir -p "$target_dir"/{bin,gamedata,configs/menus,plugins/MyPlugin}
echo "OLD-BIN"                 > "$target_dir/bin/swiftly.so"
echo "OLD-GAMEDATA"            > "$target_dir/gamedata/offsets.json"
echo "OPERATOR-EDITED-CORE"    > "$target_dir/configs/core.jsonc"
echo "STALE-EXAMPLE"           > "$target_dir/configs/menus/menus.example.jsonc"
echo "OPERATOR-OWN-MENUS"      > "$target_dir/configs/menus/menus.jsonc"
echo "MY-PLUGIN"               > "$target_dir/plugins/MyPlugin/plugin.dll"

# --- the block under test (copied verbatim from swiftlys2.sh) ------------
cp -rf "$swiftly_dir/bin" "$target_dir/" && \
cp -rf "$swiftly_dir/gamedata" "$target_dir/" || { echo "copy failed"; exit 1; }

cp -rn "$swiftly_dir/." "$target_dir/" 2>/dev/null || true

refreshed=0
while IFS= read -r -d '' src; do
    rel="${src#"$swiftly_dir"/}"
    mkdir -p "$target_dir/$(dirname "$rel")"
    cp -f "$src" "$target_dir/$rel" && refreshed=$((refreshed + 1))
done < <(find "$swiftly_dir" -type f -name '*.example.*' -print0)

# --- assertions ----------------------------------------------------------
echo "swiftlys2.sh update copy rules"
check "bin replaced"                 "NEW-BIN"               "$(cat "$target_dir/bin/swiftly.so")"
check "gamedata replaced"            "NEW-GAMEDATA"          "$(cat "$target_dir/gamedata/offsets.json")"
check "edited config NOT clobbered"  "OPERATOR-EDITED-CORE"  "$(cat "$target_dir/configs/core.jsonc")"
check "operator's own menus.jsonc"   "OPERATOR-OWN-MENUS"    "$(cat "$target_dir/configs/menus/menus.jsonc")"
check "stale template refreshed"     "NEW-MENUS-EXAMPLE"     "$(cat "$target_dir/configs/menus/menus.example.jsonc")"
check "brand-new config appears"     "NEW-FILE-THIS-RELEASE" "$(cat "$target_dir/configs/brandnew.jsonc")"
check "plugins untouched"            "MY-PLUGIN"             "$(cat "$target_dir/plugins/MyPlugin/plugin.dll")"
check "templates refreshed count"    "1"                     "$refreshed"

# A second run must change nothing further (updates re-run on every boot).
before=$(find "$target_dir" -type f -exec md5sum {} + | sort -k2 | md5sum)
cp -rf "$swiftly_dir/bin" "$target_dir/" >/dev/null 2>&1
cp -rf "$swiftly_dir/gamedata" "$target_dir/" >/dev/null 2>&1
cp -rn "$swiftly_dir/." "$target_dir/" 2>/dev/null || true
while IFS= read -r -d '' src; do
    rel="${src#"$swiftly_dir"/}"; cp -f "$src" "$target_dir/$rel"
done < <(find "$swiftly_dir" -type f -name '*.example.*' -print0)
after=$(find "$target_dir" -type f -exec md5sum {} + | sort -k2 | md5sum)
check "idempotent on re-run"         "$before"               "$after"

rm -rf "$root"
echo
echo "passed=$PASS failed=$FAIL"
[ "$FAIL" -eq 0 ]
