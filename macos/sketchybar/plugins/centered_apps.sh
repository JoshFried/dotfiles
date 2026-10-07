#!/bin/bash

is_centered_app() {
    case "$1" in
        Messages|Music|Podcasts|Notes|Telegram|Finder|\
        com.apple.MobileSMS|com.apple.Music|com.apple.podcasts|com.apple.Notes|\
        ru.keepcoder.Telegram|com.apple.finder)
            return 0
            ;;
    esac

    return 1
}
