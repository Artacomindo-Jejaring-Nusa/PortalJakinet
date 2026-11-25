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

# Determine workspace root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [ -n "$CI_PRIMARY_REPOSITORY_PATH" ] && [ -d "$CI_PRIMARY_REPOSITORY_PATH" ]; then
    REPO_ROOT="$CI_PRIMARY_REPOSITORY_PATH"
elif [ -n "$CI_WORKSPACE" ] && [ -d "$CI_WORKSPACE" ]; then
    REPO_ROOT="$CI_WORKSPACE"
fi

echo "Repository Root: $REPO_ROOT"

echo "=== Resolving Flutter Dependencies ==="
cd "$REPO_ROOT/flutter_app"
flutter pub get

# Fix trailing commas in pub-cache if needed for Swift compilers
echo "=== Checking & Fixing Swift Trailing Commas in ~/.pub-cache ==="
python3 -c "
import os, re
cache_dir = os.path.expanduser('~/.pub-cache')
if os.path.exists(cache_dir):
    pattern = re.compile(r',\s*([)\]])')
    count = 0
    for root, dirs, files in os.walk(cache_dir):
        for f in files:
            if f.endswith('.swift'):
                p = os.path.join(root, f)
                with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
                    content = fp.read()
                new_content = pattern.sub(r'\1', content)
                if new_content != content:
                    with open(p, 'w', encoding='utf-8') as fp:
                        fp.write(new_content)
                    count += 1
    print(f'Fixed trailing commas in {count} files')
" || true

echo "=== Preparing iOS Build Configuration ==="
flutter build ios --config-only --no-codesign || (cd ios && pod install)

echo "=== ci_post_clone.sh completed successfully! ==="
