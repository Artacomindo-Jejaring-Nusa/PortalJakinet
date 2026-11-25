#!/bin/sh
set -e

# Setup Homebrew environment
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:$HOME/flutter/bin"

# Install Flutter if not present
if ! command -v flutter >/dev/null 2>&1; then
    echo "=== Installing Flutter Stable ==="
    cd "$HOME"
    if [ ! -d "$HOME/flutter" ]; then
        git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
    fi
    export PATH="$PATH:$HOME/flutter/bin"
fi

flutter --version

echo "=== Resolving Flutter Dependencies ==="
cd "$CI_WORKSPACE/flutter_app"
flutter pub get

echo "=== Installing iOS CocoaPods ==="
cd "$CI_WORKSPACE/flutter_app/ios"
pod install

echo "=== ci_post_clone.sh completed successfully! ==="
