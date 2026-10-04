#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_DIR=""
REPO_OVERRIDE="${DOTFILES_REPO:-}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
LOG_FILE="$STATE_DIR/bootstrap-linux.log"
MODE="install"
FAILURES=0
WARNINGS=0

NPM_PACKAGES=(
    typescript
    ts-node
    @fsouza/prettierd
)

LEGACY_GLIBC_NODE_LINE="22"
NODE_INSTALLER_URL="https://unofficial-builds.nodejs.org/install-node.sh"

TMUX_PLUGINS=(
	vim-tmux-navigator
	tmux-kanagawa
	tmux-sensible
	tmux-resurrect
	tmux-continuum
	tmux-thumbs
	tmux-fzf-url
)

usage() {
	cat <<'EOF'
Usage: ./bootstrap-linux.sh [--check] [--repo PATH]

Install the shared core and development profiles on a Linux host. Homebrew
manages development tools; the system package manager is used only when
Homebrew build prerequisites are missing.

Options:
  --check  Audit without changing the host
  --repo   Use an explicit dotfiles repository
  -h       Show this help
EOF
}

color() {
	local code="$1"
	shift
	if [ -t 1 ]; then
		printf '\033[%sm%s\033[0m\n' "$code" "$*"
	else
		printf '%s\n' "$*"
	fi
}

section() { color "1;34" "==> $*"; }
success() { color "1;32" "  OK: $*"; }
warning() {
	color "1;33" "  WARN: $*"
	WARNINGS=$((WARNINGS + 1))
}
failure() {
	color "1;31" "  FAIL: $*"
	FAILURES=$((FAILURES + 1))
}

run_logged() {
	printf '+ ' >>"$LOG_FILE"
	printf '%q ' "$@" >>"$LOG_FILE"
	printf '\n' >>"$LOG_FILE"
	"$@" >>"$LOG_FILE" 2>&1
}

parse_arguments() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--check)
			MODE="check"
			shift
			;;
		--repo)
			if [ "$#" -lt 2 ]; then
				printf 'Missing value for --repo\n' >&2
				usage >&2
				exit 2
			fi
			REPO_OVERRIDE="$2"
			shift 2
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			printf 'Unknown option: %s\n' "$1" >&2
			usage >&2
			exit 2
			;;
		esac
	done
}

require_linux() {
	if [ "$(uname -s)" != "Linux" ]; then
		failure "This installer only supports Linux"
		exit 1
	fi
}

is_dotfiles_repository() {
	local candidate="$1"
	[ -f "$candidate/dotfiles.toml" ] &&
		[ -f "$candidate/dotfiles-cli/Cargo.toml" ]
}

resolve_script_directory() {
	local source_path="${BASH_SOURCE[0]}"
	local source_directory
	local link_target

	while [ -L "$source_path" ]; do
		source_directory="$(cd "$(dirname "$source_path")" && pwd -P)"
		link_target="$(readlink "$source_path")"
		case "$link_target" in
		/*) source_path="$link_target" ;;
		*) source_path="$source_directory/$link_target" ;;
		esac
	done

	cd "$(dirname "$source_path")" && pwd -P
}

canonical_directory() {
	local path="${1/#\~/$HOME}"
	[ -d "$path" ] || return 1
	cd "$path" && pwd -P
}

resolve_dotfiles_directory() {
	local candidate
	local git_root
	local -a candidates=()

	if [ -n "$REPO_OVERRIDE" ]; then
		candidate="$(canonical_directory "$REPO_OVERRIDE" 2>/dev/null || true)"
		if [ -n "$candidate" ] && is_dotfiles_repository "$candidate"; then
			DOTFILES_DIR="$candidate"
			return
		fi
		failure "--repo is not a complete dotfiles repository: $REPO_OVERRIDE"
		return 1
	fi

	candidates+=("$(resolve_script_directory)")
	candidates+=("$PWD")

	if command -v git >/dev/null 2>&1; then
		git_root="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || true)"
		[ -z "$git_root" ] || candidates+=("$git_root")
	fi

	candidates+=("$HOME/repos/dotfiles")
	candidates+=("$HOME/dotfiles")
	candidates+=("$HOME/.dotfiles")

	for candidate in "${candidates[@]}"; do
		candidate="$(canonical_directory "$candidate" 2>/dev/null || true)"
		if [ -n "$candidate" ] && is_dotfiles_repository "$candidate"; then
			DOTFILES_DIR="$candidate"
			return
		fi
	done

	failure "Could not locate the full dotfiles repository"
	printf 'Run with --repo PATH or execute from a complete repository clone.\n' >&2
	return 1
}

prepare_log() {
	if ! mkdir -p "$STATE_DIR" 2>/dev/null || ! touch "$LOG_FILE" 2>/dev/null; then
		STATE_DIR="${TMPDIR:-/tmp}/dotfiles-$UID"
		LOG_FILE="$STATE_DIR/bootstrap-linux.log"
		mkdir -p "$STATE_DIR"
		touch "$LOG_FILE"
		warning "Using fallback log directory $STATE_DIR"
	fi
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

missing_prerequisites() {
	local command
	for command in git curl file make cc; do
		command_exists "$command" || printf '%s\n' "$command"
	done
}

install_system_prerequisites() {
	section "Linux prerequisites"

	local missing
	missing="$(missing_prerequisites)"
	if [ -z "$missing" ]; then
		success "Homebrew build prerequisites"
		return
	fi

	if [ "$MODE" = "check" ]; then
		failure "Missing system commands: ${missing//$'\n'/ }"
		return
	fi

	local privilege=()
	if [ "$(id -u)" -ne 0 ]; then
		if command_exists sudo; then
			privilege=(sudo)
		else
			failure "Missing prerequisites and sudo is unavailable: ${missing//$'\n'/ }"
			return
		fi
	fi

	if command_exists apt-get; then
		if run_logged "${privilege[@]}" apt-get update &&
			run_logged "${privilege[@]}" apt-get install -y \
				build-essential procps curl file git; then
			success "Homebrew build prerequisites"
		else
			failure "Failed to install Homebrew prerequisites; see $LOG_FILE"
		fi
	elif command_exists dnf; then
		install_rpm_prerequisites "${privilege[@]}" dnf
	elif command_exists yum; then
		install_rpm_prerequisites "${privilege[@]}" yum
	else
		failure "Unsupported package manager; install Homebrew prerequisites manually"
	fi
}

install_rpm_prerequisites() {
	local privilege=()
	while [ "$#" -gt 1 ]; do
		privilege+=("$1")
		shift
	done
	local package_manager="$1"

	if run_logged "${privilege[@]}" "$package_manager" install -y \
		gcc gcc-c++ make glibc-devel procps-ng curl file git; then
		success "Homebrew build prerequisites"
	else
		failure "Failed to install Homebrew prerequisites; see $LOG_FILE"
	fi
}

find_brew() {
	if command_exists brew; then
		command -v brew
	elif [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
		printf '%s\n' /home/linuxbrew/.linuxbrew/bin/brew
	elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
		printf '%s\n' "$HOME/.linuxbrew/bin/brew"
	fi
}

load_homebrew() {
	local brew_path
	brew_path="$(find_brew)"
	[ -n "$brew_path" ] || return 1
	eval "$("$brew_path" shellenv)"
}

homebrew_version() {
	local version
	version="$(brew --version)"
	printf '%s\n' "${version%%$'\n'*}"
}

ensure_homebrew() {
	section "Homebrew"

	if load_homebrew; then
		success "$(homebrew_version)"
		return
	fi

	if [ "$MODE" = "check" ]; then
		failure "Homebrew is not installed"
		return
	fi

	local installer
	if ! installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
		failure "Failed to download the Homebrew installer"
		return
	fi

	if NONINTERACTIVE=1 /bin/bash -c "$installer" >>"$LOG_FILE" 2>&1 &&
		load_homebrew; then
		success "$(homebrew_version)"
	else
		failure "Homebrew installation failed or brew could not be located; see $LOG_FILE"
    fi
}

refresh_homebrew() {
    if [ "$MODE" != "install" ] || ! command_exists brew; then
        return
    fi

    section "Homebrew metadata"
    if run_logged brew update; then
        success "Homebrew and formula metadata updated"
    else
        failure "Failed to update Homebrew; see $LOG_FILE"
    fi
}

ensure_rust_bootstrap() {
	section "Rust bootstrap"

	if command_exists cargo; then
		success "$(cargo --version)"
		return
	fi

	if ! command_exists brew; then
		failure "Cannot install Rust because Homebrew is unavailable"
		return
	fi

	if [ "$MODE" = "check" ]; then
		failure "Cargo is unavailable"
		return
	fi

	if ! brew list --formula rustup >/dev/null 2>&1 &&
		! run_logged brew install rustup; then
		failure "Failed to install rustup; see $LOG_FILE"
		return
	fi

	if command_exists rustup-init &&
		run_logged rustup-init -y --no-modify-path &&
		[ -s "$HOME/.cargo/env" ]; then
		source "$HOME/.cargo/env"
		success "$(cargo --version)"
	else
		failure "Failed to initialize Rust; see $LOG_FILE"
	fi
}

run_dotfiles_cli() {
	cargo run --quiet --release \
		--manifest-path "$DOTFILES_DIR/dotfiles-cli/Cargo.toml" \
		-- \
		--repo "$DOTFILES_DIR" \
		--log-directory "$STATE_DIR/cli" \
		-vv \
		"$@"
}

reconcile_shared_profiles() {
	section "Shared dotfiles profiles"

	if ! command_exists cargo; then
		failure "Cannot run the dotfiles CLI because Cargo is unavailable"
		return
	fi

	if [ "$MODE" = "check" ]; then
		if run_dotfiles_cli audit --profile core --profile development; then
			success "Core and development profiles"
		else
			failure "Core or development profile has drift"
		fi
	elif run_dotfiles_cli apply \
		--profile core \
		--profile development \
		--yes; then
		success "Core and development profiles"
	else
		failure "Failed to reconcile core or development profiles"
	fi
}

load_nvm() {
	local nvm_prefix
	nvm_prefix="$(brew --prefix nvm 2>/dev/null || true)"
	[ -s "$nvm_prefix/nvm.sh" ] || return 1
	export NVM_DIR="$HOME/.nvm"
	if [ "$MODE" = "install" ]; then
		mkdir -p "$NVM_DIR"
	elif [ ! -d "$NVM_DIR" ]; then
		return 1
	fi
	source "$nvm_prefix/nvm.sh"
}

node_is_usable() {
	command_exists node && node --version >/dev/null 2>&1
}

activate_nvm_node() {
	local selector="$1"
	ACTIVE_NODE_VERSION="$(nvm version "$selector" 2>/dev/null || true)"
	if [ -z "$ACTIVE_NODE_VERSION" ] || [ "$ACTIVE_NODE_VERSION" = "N/A" ]; then
		return 1
	fi

	nvm use --silent "$ACTIVE_NODE_VERSION" >/dev/null 2>&1 &&
		node_is_usable
}

requires_legacy_glibc_node() {
	[ "$(uname -s)" = "Linux" ] || return 1
	[ "$(uname -m)" = "x86_64" ] || return 1
	command_exists getconf || return 1

	local glibc_version
	glibc_version="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{ print $2 }')"
	[ -n "$glibc_version" ] || return 1
	[ "$(printf '2.28\n%s\n' "$glibc_version" | sort -V | head -1)" != "2.28" ]
}

node_version_from_download_url() {
	local archive="${1##*/}"
	local version="${archive#node-}"
	printf '%s\n' "${version%%-linux-*}"
}

install_legacy_glibc_node() {
	local installer="$STATE_DIR/install-node.sh"
	local download_url
	local install_directory

	if ! run_logged curl -fsSL -o "$installer" "$NODE_INSTALLER_URL"; then
		return 1
	fi

	download_url="$(
		bash "$installer" \
			--line "$LEGACY_GLIBC_NODE_LINE" \
			--platform x64-glibc-217 \
			--dry-run 2>>"$LOG_FILE"
	)" || return 1
	ACTIVE_NODE_VERSION="$(node_version_from_download_url "$download_url")"
	install_directory="$NVM_DIR/versions/node/$ACTIVE_NODE_VERSION"
	mkdir -p "$install_directory"

	run_logged bash "$installer" \
		--line "$LEGACY_GLIBC_NODE_LINE" \
		--platform x64-glibc-217 \
		--dir "$install_directory" \
		--yes
}

ensure_node() {
	section "Node.js and global packages"

	if ! command_exists brew || ! load_nvm; then
		failure "NVM is unavailable"
		return
	fi

	ACTIVE_NODE_VERSION=""
	if ! activate_nvm_node default && ! activate_nvm_node 'lts/*'; then
		if [ "$MODE" = "check" ]; then
			failure "No installed NVM-managed Node.js version runs on this host"
			return
		fi

		if requires_legacy_glibc_node; then
			if ! install_legacy_glibc_node; then
				failure "Failed to install the glibc-compatible Node.js build; see $LOG_FILE"
				return
			fi
		elif ! nvm install --lts >>"$LOG_FILE" 2>&1; then
			failure "Failed to install Node.js LTS; see $LOG_FILE"
			return
		else
			ACTIVE_NODE_VERSION="$(nvm version 'lts/*')"
		fi

		if ! activate_nvm_node "$ACTIVE_NODE_VERSION"; then
			failure "Installed Node.js $ACTIVE_NODE_VERSION does not run on this host"
			return
		fi
	fi
	success "Node $(node --version)"

	if [ "$MODE" = "install" ] &&
		! nvm alias default "$ACTIVE_NODE_VERSION" >>"$LOG_FILE" 2>&1; then
		warning "Could not set the default NVM alias"
	fi

	local package
	for package in "${NPM_PACKAGES[@]}"; do
		if npm list --global --depth=0 "$package" >/dev/null 2>&1; then
			success "npm:$package"
		elif [ "$MODE" = "check" ]; then
			failure "Global npm package is missing: $package"
		elif run_logged npm install --global "$package"; then
			success "npm:$package"
		else
			failure "Failed to install npm:$package; see $LOG_FILE"
		fi
	done
}

ensure_go_tool() {
	local binary="$1"
	local module="$2"

	if command_exists "$binary"; then
		success "$binary"
	elif [ "$MODE" = "check" ]; then
		failure "$binary is missing"
	elif run_logged go install "$module@latest"; then
		success "$binary"
	else
		failure "Failed to install $binary; see $LOG_FILE"
	fi
}

ensure_go_tools() {
	section "Go development tools"

	if ! command_exists go; then
		failure "Go is unavailable"
		return
	fi

	local go_bin
	go_bin="$(go env GOBIN)"
	[ -n "$go_bin" ] || go_bin="$(go env GOPATH)/bin"
	export PATH="$go_bin:$PATH"

	ensure_go_tool "gopls" "golang.org/x/tools/gopls"
	ensure_go_tool "goimports-reviser" "github.com/incu6us/goimports-reviser/v3"
	ensure_go_tool "golangci-lint" "github.com/golangci/golangci-lint/cmd/golangci-lint"
}

ensure_runtime_directories() {
	section "Runtime directories"

	local directory
	for directory in "$HOME/.vim/undodir" "$HOME/tmp"; do
		if [ -d "$directory" ]; then
			success "$directory"
		elif [ "$MODE" = "check" ]; then
			failure "$directory is missing"
		else
			mkdir -p "$directory"
			success "$directory"
		fi
	done
}

ensure_tmux_plugins() {
	section "Tmux plugins"

	local missing=()
	local plugin
	for plugin in "${TMUX_PLUGINS[@]}"; do
		[ -d "$HOME/.tmux/plugins/$plugin/.git" ] || missing+=("$plugin")
	done

	if [ "${#missing[@]}" -eq 0 ]; then
		success "All configured plugins"
		return
	fi

	if [ "$MODE" = "check" ]; then
		failure "Missing tmux plugins: ${missing[*]}"
		return
	fi

	if [ ! -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ] ||
		! run_logged "$HOME/.tmux/plugins/tpm/bin/install_plugins"; then
		failure "Failed to install tmux plugins; see $LOG_FILE"
		return
	fi

	missing=()
	for plugin in "${TMUX_PLUGINS[@]}"; do
		[ -d "$HOME/.tmux/plugins/$plugin/.git" ] || missing+=("$plugin")
	done
	if [ "${#missing[@]}" -eq 0 ]; then
		success "Installed configured plugins"
	else
		failure "Tmux plugins remain missing: ${missing[*]}"
	fi
}

print_summary() {
	printf '\n'
	if [ "$FAILURES" -eq 0 ]; then
		color "1;32" "Linux bootstrap complete with $WARNINGS warning(s)."
	else
		color "1;31" \
			"Linux bootstrap completed with $FAILURES failure(s) and $WARNINGS warning(s)."
	fi
	printf 'Bootstrap log: %s\n' "$LOG_FILE"
	printf 'CLI logs: %s\n' "$STATE_DIR/cli"
	printf 'Open a new zsh session, then launch Neovim once to install its plugins.\n'
	printf 'Changing the login shell remains manual because it modifies /etc/shells.\n'
}

main() {
	parse_arguments "$@"
	require_linux
	resolve_dotfiles_directory || exit 1
	prepare_log
	: >"$LOG_FILE"
	export HOMEBREW_NO_AUTO_UPDATE=1

    install_system_prerequisites
    ensure_homebrew
    refresh_homebrew
    ensure_rust_bootstrap
	reconcile_shared_profiles
	ensure_node
	ensure_go_tools
	ensure_runtime_directories
	ensure_tmux_plugins
	print_summary

	[ "$FAILURES" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	main "$@"
fi
