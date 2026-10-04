#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-linux-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

source "$REPO_DIR/bootstrap-linux.sh"

TESTS=0

assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    TESTS=$((TESTS + 1))
    if [ "$expected" != "$actual" ]; then
        printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' \
            "$message" "$expected" "$actual" >&2
        exit 1
    fi
}

assert_path() {
    local path="$1"
    local message="$2"
    TESTS=$((TESTS + 1))
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        printf 'FAIL: %s\nmissing: %s\n' "$message" "$path" >&2
        exit 1
    fi
}

assert_equal "@fsouza/prettierd" "${NPM_PACKAGES[2]}" \
    "uses the maintained scoped prettierd package"
assert_equal "v22.22.1" "$(
    node_version_from_download_url \
        "https://unofficial-builds.nodejs.org/download/release/v22.22.1/node-v22.22.1-linux-x64-glibc-217.tar.xz"
)" "extracts an NVM version from an unofficial build URL"

MODE="install"
REPO_OVERRIDE=""
parse_arguments
assert_equal "install" "$MODE" "defaults to install mode"

MODE="install"
REPO_OVERRIDE=""
parse_arguments --check
assert_equal "check" "$MODE" "parses check mode"

MODE="install"
REPO_OVERRIDE=""
parse_arguments --repo /tmp/example --check
assert_equal "check" "$MODE" "accepts check and repository options together"
assert_equal "/tmp/example" "$REPO_OVERRIDE" "parses an explicit repository"

missing="$(
    command_exists() {
        [ "$1" = git ] || [ "$1" = make ]
    }
    missing_prerequisites
)"
assert_equal $'curl\nfile\ncc' "$missing" \
    "reports each missing prerequisite"

fake_bin="$TEST_ROOT/bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/brew" <<'EOF'
#!/usr/bin/env bash
printf 'fake brew\n'
EOF
chmod +x "$fake_bin/brew"
PATH="$fake_bin:/usr/bin:/bin"
assert_equal "$fake_bin/brew" "$(find_brew)" \
    "finds Homebrew from PATH"

MODE="check"
refresh_homebrew

clipboard_output="$TEST_ROOT/clipboard"
cat >"$fake_bin/pbcopy" <<'EOF'
#!/usr/bin/env bash
cat >"$CLIPBOARD_OUTPUT"
EOF
chmod +x "$fake_bin/pbcopy"

CLIPBOARD_OUTPUT="$clipboard_output" \
    PATH="$fake_bin:/usr/bin:/bin" \
    "$REPO_DIR/bin/dotfiles-copy" <<<"clipboard text"
assert_path "$clipboard_output" "uses an available clipboard backend"
assert_equal "clipboard text" "$(<"$clipboard_output")" \
    "passes standard input to the clipboard backend"

fake_repo="$TEST_ROOT/repo"
mkdir -p "$fake_repo/dotfiles-cli"
touch "$fake_repo/dotfiles-cli/Cargo.toml"
touch "$fake_repo/dotfiles.toml"
REPO_OVERRIDE="$fake_repo"
resolve_dotfiles_directory
canonical_fake_repo="$(cd "$fake_repo" && pwd -P)"
assert_equal "$canonical_fake_repo" "$DOTFILES_DIR" \
    "uses an explicit complete repository"

DOTFILES_DIR="$fake_repo"
STATE_DIR="$TEST_ROOT/state"
cargo_arguments="$TEST_ROOT/cargo-arguments"
cat >"$fake_bin/cargo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$CARGO_ARGUMENTS"
EOF
chmod +x "$fake_bin/cargo"

CARGO_ARGUMENTS="$cargo_arguments" run_dotfiles_cli audit --profile core
assert_path "$cargo_arguments" "invokes the Rust dotfiles CLI"
IFS= read -r first_cargo_argument <"$cargo_arguments"
assert_equal "run" "$first_cargo_argument" \
    "invokes Cargo's run command"
if ! grep -Fx -- "--profile" "$cargo_arguments" >/dev/null ||
    ! grep -Fx -- "core" "$cargo_arguments" >/dev/null; then
    printf 'FAIL: forwards profile arguments to the dotfiles CLI\n' >&2
    exit 1
fi
TESTS=$((TESTS + 1))

printf 'PASS: %d bootstrap-linux assertions\n' "$TESTS"
