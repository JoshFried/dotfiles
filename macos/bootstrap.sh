# Sourced by the top-level bootstrap on Darwin. prepare_platform checks for Xcode
# command-line tools. After the shared install, finish_platform registers the
# Homebrew JDK system-wide and copies the Firefox style to the first matching release
# profile.

# macOS integration for the shared bootstrap.
prepare_platform() {
    if xcode-select -p >/dev/null 2>&1; then
        return
    fi
    if [ "$MODE" = install ]; then
        xcode-select --install || true
    fi
    failure 'Install Xcode Command Line Tools and rerun bootstrap.'
    return 1
}

register_java() {
    local prefix source destination
    prefix=$(brew --prefix openjdk@21) || return 1
    source="$prefix/libexec/openjdk.jdk"
    destination=/Library/Java/JavaVirtualMachines/openjdk-21.jdk
    if [ ! -d "$source" ]; then
        failure "Missing Java bundle: $source"
    elif [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
        success 'OpenJDK 21 registered'
    elif [ -e "$destination" ] && [ ! -L "$destination" ]; then
        failure "Java destination is occupied: $destination"
    elif [ "$MODE" = check ]; then
        failure "Java registration needs updating: $destination"
    elif ! run_logged sudo ln -sfn "$source" "$destination"; then
        failure 'Could not register OpenJDK 21'
    fi
}

install_firefox_style() {
    local profile destination source="$DOTFILES_DIR/firefox/userChrome.css"
    for profile in "$HOME/Library/Application Support/Firefox/Profiles/"*.default-release; do
        [ -d "$profile" ] || continue
        destination="$profile/chrome/userChrome.css"
        if cmp -s "$source" "$destination"; then
            success 'Firefox style'
        elif [ "$MODE" = check ]; then
            failure 'Firefox style needs updating'
        elif ! mkdir -p "$profile/chrome" || ! cp "$source" "$destination"; then
            failure 'Could not install Firefox style'
        fi
        return
    done
    warning 'Open Firefox once, then rerun bootstrap to install its style.'
}

finish_platform() {
    register_java
    install_firefox_style
}
