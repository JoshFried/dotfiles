#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/aerospace-workspace-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

MOCK_AEROSPACE="$TEST_ROOT/aerospace"
COMMAND_LOG="$TEST_ROOT/commands.log"
STATE_FILE="$TEST_ROOT/workspaces.state"

cat > "$MOCK_AEROSPACE" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
    list-monitors)
        if [ "${MOCK_PHASE}" = "before" ]; then
            if [ "$3" = "%{monitor-id}" ]; then
                printf '1\n2\n3\n'
            else
                printf '1|Built-in Retina Display|true\n2|Studio Display|false\n3|DELL U2723QE|false\n'
            fi
        elif [ "$3" = "%{monitor-id}" ]; then
            printf '1\n'
        else
            printf '1|Built-in Retina Display|true\n'
        fi
        ;;
    list-windows)
        if [ "${MOCK_PHASE}" = "before" ]; then
            printf '101|5\n102|6\n103|7\n'
        else
            printf '101|1\n102|1\n103|1\n'
        fi
        ;;
    move-node-to-workspace|move-workspace-to-monitor)
        printf '%s\n' "$*" >> "${MOCK_COMMAND_LOG}"
        ;;
    *)
        printf 'Unexpected command: %s\n' "$*" >&2
        exit 1
        ;;
esac
EOF
chmod +x "$MOCK_AEROSPACE"

run_assigner() {
    MOCK_PHASE="$1" \
        MOCK_COMMAND_LOG="$COMMAND_LOG" \
        AEROSPACE_BIN="$MOCK_AEROSPACE" \
        AEROSPACE_WORKSPACE_STATE="$STATE_FILE" \
        "$REPO_DIR/macos/aerospace-workspace-assign.sh" "${@:2}"
}

run_assigner before snapshot 3
run_assigner after

for expected in \
    "move-node-to-workspace --window-id 101 5" \
    "move-node-to-workspace --window-id 102 6" \
    "move-node-to-workspace --window-id 103 7"
do
    grep -Fxq "$expected" "$COMMAND_LOG"
done

for workspace in {1..10}; do
    grep -Fxq "move-workspace-to-monitor --workspace $workspace 1" "$COMMAND_LOG"
done

printf 'AeroSpace workspace transition test passed\n'
