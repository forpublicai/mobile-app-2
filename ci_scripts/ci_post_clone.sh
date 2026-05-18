#!/bin/sh
set -euo pipefail

# Xcode Cloud checks out the repo cleanly. Flutter and CocoaPods generated
# files are not committed, so create them before Xcode resolves build settings.
cd "${CI_WORKSPACE:-$(pwd)}"

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_DIR="$HOME/flutter"
  if [ ! -d "$FLUTTER_DIR" ]; then
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

flutter --version
flutter pub get

# This project uses generated Dart sources. Keep this before pod install so
# native plugin/config generation sees the final dependency graph.
dart run build_runner build --delete-conflicting-outputs

cd ios
pod install
