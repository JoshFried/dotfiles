# Sourced by the top-level bootstrap on Linux. prepare_platform checks for compiler
# and build commands and installs missing prerequisites through the available system
# package manager in install mode. The shared installer handles Homebrew and the
# AL2-compatible Node build.

# Linux prerequisites for the shared bootstrap.
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


prepare_platform() {
    install_system_prerequisites
}

finish_platform() {
    :
}
