#!/data/data/com.termux/files/usr/bin/bash
set -e
cd "$(dirname "$0")/.."

if [ ! -d android ]; then
  npx cap add android
fi

MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q 'android.permission.CAMERA' "$MANIFEST"; then
  sed -i '/<manifest /a\    <uses-permission android:name="android.permission.CAMERA" />' "$MANIFEST"
fi

npx cap sync android

echo
echo "Project synchronized."
echo "Debug APK: android/app/build/outputs/apk/debug/app-debug.apk"
