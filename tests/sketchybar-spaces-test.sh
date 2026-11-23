#!/usr/bin/env bash
# Exercise the workspace renderers with fixture monitor IDs and app listings to
# catch display ordering and icon-selection regressions.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sketchybar-spaces-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/config/plugins"
export CONFIG_DIR="$TEST_ROOT/config"
export PATH="$TEST_ROOT/bin:$PATH"
export MOCK_DISPLAYS="$TEST_ROOT/displays.json"
export MOCK_SCREEN_IDS="$TEST_ROOT/screen-ids"
export MOCK_COMMAND_LOG="$TEST_ROOT/commands.jsonl"

for plugin in display_map.sh display_ids.js icon_map_fn.sh centered_apps.sh; do
    ln -s "$REPO_DIR/macos/sketchybar/plugins/$plugin" "$CONFIG_DIR/plugins/$plugin"
done
for plugin in aerospace_events.sh system_stats.sh; do
    printf '#!/bin/bash\nexit 0\n' > "$CONFIG_DIR/plugins/$plugin"
    chmod +x "$CONFIG_DIR/plugins/$plugin"
done

cat > "$TEST_ROOT/bin/aerospace" <<'EOF'
#!/bin/bash
case "$1" in
    list-workspaces)
        printf '1|2|true|true\n5|1|true|false\n9|3|true|false\n10|3|false|false\n'
        ;;
    list-windows)
        printf '1|Terminal|com.apple.Terminal\n9|Firefox|org.mozilla.firefox\n9|Firefox|org.mozilla.firefox\n'
        ;;
    list-monitors)
        printf 'LG ULTRAGEAR|1|false\nBuilt-in Retina Display|2|false\nLG ULTRAGEAR|3|true\n'
        ;;
    *)
        exit 1
        ;;
esac
EOF

cat > "$TEST_ROOT/bin/sketchybar" <<'EOF'
#!/bin/bash
if [ "$1" = --query ] && [ "$2" = displays ]; then
    cat "$MOCK_DISPLAYS"
else
    jq -nc --args '$ARGS.positional' -- "$@" >> "$MOCK_COMMAND_LOG"
fi
EOF

cat > "$TEST_ROOT/bin/osascript" <<'EOF'
#!/bin/bash
cat "$MOCK_SCREEN_IDS"
EOF
chmod +x "$TEST_ROOT/bin/"*

printf '1|3\n2|1\n3|2\n' > "$MOCK_SCREEN_IDS"
cat > "$MOCK_DISPLAYS" <<'EOF'
[
    {"arrangement-id":1,"DirectDisplayID":3},
    {"arrangement-id":2,"DirectDisplayID":2},
    {"arrangement-id":3,"DirectDisplayID":1}
]
EOF

run_spaces() {
    : > "$MOCK_COMMAND_LOG"
    bash "$REPO_DIR/macos/sketchybar/plugins/space.sh"
    jq -s '
        .[0] |
        reduce .[] as $argument
            ({items: {}, current: null, next_is_item: false};
             if $argument == "--set" then
                 .next_is_item = true
             elif .next_is_item then
                 .current = $argument | .next_is_item = false |
                 .items[$argument] = []
             else
                 .items[.current] += [$argument]
             end) |
        .items
    ' "$MOCK_COMMAND_LOG" > "$TEST_ROOT/items.json"
}

run_spaces
jq -e '
    (.["space.1"] | contains(["display=3", "drawing=on", "background.color=0xff7E9CD8"])) and
    (.["space.5"] | contains(["display=1", "drawing=on", "background.color=0xff54546D"])) and
    (.["space.9"] | contains(["display=2", "drawing=on", "label= :firefox:"])) and
    (.["space.10"] | contains(["display=2", "drawing=off"])) and
    (.["space.2"] == ["drawing=off"])
' "$TEST_ROOT/items.json" > /dev/null

: > "$MOCK_COMMAND_LOG"
bash "$REPO_DIR/macos/sketchybar/sketchybarrc"
jq -se '
    any(.[]; contains(["--set", "media", "display=2"])) and
    any(.[]; contains(["--subscribe", "space.1", "aerospace_state_change", "display_change", "system_woke"]))
' "$MOCK_COMMAND_LOG" > /dev/null

printf '[{"arrangement-id":1,"DirectDisplayID":3},{"arrangement-id":2,"DirectDisplayID":1}]\n' > "$MOCK_DISPLAYS"
run_spaces
jq -e '
    (.["space.1"] | contains(["display=2", "drawing=on"])) and
    (.["space.9"] == ["drawing=off"])
' "$TEST_ROOT/items.json" > /dev/null

printf '[{"arrangement-id":1,"DirectDisplayID":1}]\n' > "$MOCK_DISPLAYS"
printf '1|1\n' > "$MOCK_SCREEN_IDS"
source "$CONFIG_DIR/plugins/display_map.sh"
load_display_map
[ "${SKETCHYBAR_DISPLAYS[1]}" = 1 ]
[ -z "${SKETCHYBAR_DISPLAYS[2]:-}" ]

printf 'invalid display response\n' > "$MOCK_DISPLAYS"
run_spaces
jq -e 'all(.[]; . == ["drawing=off"])' "$TEST_ROOT/items.json" > /dev/null

printf 'SketchyBar display mapping tests passed\n'
