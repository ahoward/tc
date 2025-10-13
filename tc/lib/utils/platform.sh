#!/usr/bin/env bash
# tc platform detection
# figuring out what island we're on 🚁

# detect operating system
tc_detect_os() {
    local os=""

    case "$(uname -s)" in
        Linux*)
            os="linux"
            ;;
        Darwin*)
            os="macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            os="windows"
            ;;
        *)
            os="unknown"
            ;;
    esac

    echo "$os"
}

# detect cpu cores for parallel execution
tc_detect_cpu_cores() {
    local cores=$TC_PARALLEL_DEFAULT  # fallback
    local os=$(tc_detect_os)

    case "$os" in
        linux)
            if command -v nproc >/dev/null 2>&1; then
                cores=$(nproc)
            elif [ -f /proc/cpuinfo ]; then
                cores=$(grep -c ^processor /proc/cpuinfo)
            fi
            ;;
        macos)
            if command -v sysctl >/dev/null 2>&1; then
                cores=$(sysctl -n hw.ncpu 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo $TC_PARALLEL_DEFAULT)
            fi
            ;;
        windows)
            if [ -n "$NUMBER_OF_PROCESSORS" ]; then
                cores=$NUMBER_OF_PROCESSORS
            fi
            ;;
    esac

    # ensure cores is a positive integer
    if ! [[ "$cores" =~ ^[0-9]+$ ]] || [ "$cores" -lt 1 ]; then
        cores=$TC_PARALLEL_DEFAULT
    fi

    echo "$cores"
}

# check if we're running in a tty (for color output)
tc_is_tty() {
    [ -t 1 ]
    return $?
}

# check if a command exists
tc_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# get shell type
tc_detect_shell() {
    if [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    else
        echo "sh"
    fi
}

# check posix compatibility
tc_check_posix() {
    # check for basic posix commands
    local required_commands="cd pwd ls cat grep sed awk"
    local missing=()

    for cmd in $required_commands; do
        if ! tc_command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        tc_error "missing posix commands: ${missing[*]}"
        return 1
    fi

    return 0
}
