#!/data/data/com.termux/files/usr/bin/bash

echo "=============================================="
echo "🚀 FINAL BUILD (No deprecated properties)"
echo "=============================================="

# 1. تنظيف الكاش بالكامل
echo "🧹 Cleaning all caches..."
rm -rf ~/.gradle/caches/
rm -rf android/.gradle/
rm -rf android/app/build/
rm -rf www/
echo "✅ Caches cleaned."

# 2. البحث عن ملف HTML
echo "🔍 Searching for HTML file..."
HTML_FILE=""
if [ -f "index.html" ]; then
    HTML_FILE="index.html"
elif [ -f "index.htm" ]; then
    HTML_FILE="index.htm"
elif [ -f "accueil.html" ]; then
    HTML_FILE="accueil.html"
elif [ -f "accueil.htm" ]; then
    HTML_FILE="accueil.htm"
else
    HTML_FILE=$(ls *.html *.htm 2>/dev/null | head -1)
fi

if [ -z "$HTML_FILE" ]; then
    echo "❌ No HTML file found! Create index.html"
    exit 1
fi
echo "✅ Using: $HTML_FILE"

# 3. إنشاء www ونسخ الملفات
echo "📁 Copying files to www..."
mkdir -p www
cp "$HTML_FILE" www/index.html
for folder in assets images scripts vendor css js; do
    [ -d "$folder" ] && cp -r "$folder" www/ 2>/dev/null
done
cp -f *.js *.css www/ 2>/dev/null
echo "✅ www ready."

# 4. تعيين JAVA_HOME تلقائياً
echo "☕ Setting JAVA_HOME..."
JAVA_PATH=$(find /data/data/com.termux/files/usr -name "java" -type f 2>/dev/null | head -1)
if [ -z "$JAVA_PATH" ]; then
    echo "❌ Java not found! Install: pkg install openjdk-17"
    exit 1
fi
JAVA_HOME=$(dirname $(dirname "$JAVA_PATH"))
export JAVA_HOME
export PATH=$JAVA_HOME/bin:$PATH
echo "✅ JAVA_HOME: $JAVA_HOME"
java -version 2>&1 | head -1

# 5. نسخ إلى android
echo "📦 npx cap copy android..."
npx cap copy android
if [ $? -ne 0 ]; then
    echo "❌ cap copy failed."
    exit 1
fi
echo "✅ Copy done."

# 6. زيادة versionCode
VERSION_FILE="android/app/build.gradle"
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(grep -oP 'versionCode \K[0-9]+' "$VERSION_FILE")
    NEW=$((CURRENT + 1))
    sed -i "s/versionCode $CURRENT/versionCode $NEW/" "$VERSION_FILE"
    echo "✅ Version bumped: $CURRENT → $NEW"
fi

# 7. كتابة gradle.properties صحيح (بدون enableAapt2)
echo "📝 Writing gradle.properties..."
cat > android/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true
EOF

# 8. بناء APK (مع --no-daemon)
echo "🛠️ Building APK (may take 3-5 minutes)..."
cd android
./gradlew assembleDebug --no-daemon
if [ $? -ne 0 ]; then
    echo "❌ Build failed. See error above."
    cd ..
    exit 1
fi
cd ..

# 9. حفظ APK
APK_SOURCE="android/app/build/outputs/apk/debug/app-debug.apk"
APK_DEST="$HOME/Zarouali_Final.apk"
if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "$APK_DEST"
    echo "✅ APK saved: $APK_DEST"
    ls -lh "$APK_DEST"
else
    echo "❌ APK not found."
    exit 1
fi

# 10. تثبيت عبر ADB إن أمكن
if command -v adb &> /dev/null; then
    echo "📱 Installing via ADB..."
    PACKAGE=$(grep -E "appId" capacitor.config.ts | head -1 | sed -E "s/.*['\"]:?['\"]?([^'\"]+)['\"]?.*/\1/")
    [ ! -z "$PACKAGE" ] && adb uninstall "$PACKAGE" 2>/dev/null
    adb install -r "$APK_DEST"
    echo "✅ Installed."
else
    echo "⚠️ ADB not found. Copy $APK_DEST to phone manually."
fi

echo "=============================================="
echo "🎉 DONE! APK ready: $APK_DEST"
echo "=============================================="
