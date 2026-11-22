#!/usr/bin/env bash
set -euo pipefail

# Build APK + Linux bundle and publish a versioned GitHub release
# for the version in flutter_app/pubspec.yaml.

JDK17="/usr/lib/jvm/java-17-openjdk"
if [[ -d "$JDK17" ]]; then
  export JAVA_HOME="$JDK17"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

REPO="olaks/spraywall"
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT/flutter_app"

VERSION=$(awk -F'[ +]' '/^version:/ {print $2}' pubspec.yaml)
if [[ -z "$VERSION" ]]; then
  echo "Could not parse version from pubspec.yaml" >&2
  exit 1
fi
TAG="v$VERSION"

echo "Releasing $TAG"

if ! git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Tag $TAG does not exist locally — create & push it first." >&2
  exit 1
fi

NOTES="${1:-Release $TAG}"

# CI no longer runs on push; this and the pre-commit hook are the gates
# before a build goes out. Skip it with SKIP_CHECKS=1 when re-cutting a
# release that has already been checked.
if [[ "${SKIP_CHECKS:-0}" != "1" ]]; then
  "$ROOT/scripts/check.sh"
fi

# The tests run on the VM only, so a web-only break (the drift worker, the
# WASM SQLite assets, a dart:html import) would otherwise ship unnoticed.
echo "Checking the web build..."
flutter build web --wasm

# What the VM tests can't reach. Walk it on real targets before tagging.
cat <<'CHECKLIST'
Manual checklist (spec: Testing Decisions):
  [ ] Web: add a photo, reload; it is still there and storage is OPFS, not memory
  [ ] Android: taking a wall photo with the camera works
  [ ] Linux: picking a wall photo from a file works
  [ ] Marks look right on the sample wall photo
CHECKLIST

echo "Building release APK..."
flutter pub get
flutter build apk --release
APK="build/app/outputs/flutter-apk/app-release.apk"
APK_NAMED="build/app/outputs/flutter-apk/spraywall-$TAG.apk"
cp "$APK" "$APK_NAMED"

echo "Building Linux release..."
flutter build linux --release
LINUX_ZIP="build/linux/x64/release/spraywall-linux-$TAG.zip"
rm -f "$LINUX_ZIP"
bsdtar -a -cf "$LINUX_ZIP" --options zip:compression=deflate -C build/linux/x64/release bundle

echo
echo "Artifacts:"
echo "  $APK_NAMED"
echo "  $LINUX_ZIP"
echo

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Release $TAG already exists — uploading artifacts (--clobber)."
  gh release upload "$TAG" "$APK_NAMED" "$LINUX_ZIP" --clobber --repo "$REPO"
else
  echo "Creating release $TAG..."
  gh release create "$TAG" "$APK_NAMED" "$LINUX_ZIP" \
    --repo "$REPO" \
    --title "$TAG" \
    --notes "$NOTES"
fi

echo "Done: https://github.com/$REPO/releases/tag/$TAG"
