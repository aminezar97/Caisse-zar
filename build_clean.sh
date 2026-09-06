#!/data/data/com.termux/files/usr/bin/bash

echo "=========================================="
echo "🧹 Cleaning & Building APK (Fix AAPT2)"
echo "=========================================="

# 1. قتل عمليات Java القديمة
pkill -f java 2>/dev/null

# 2. حذف كاش Gradle بالكامل (أضمن حل)
echo "🗑️ Removing Gradle caches..."
rm -rf ~/.gradle/caches/
rm -rf android/.gradle/
rm -rf android/app/build/
echo "✅ Cache cleared."

# 3. التأكد من استخدام Java 11 (الأكثر توافقاً)
# Termux يستخدم openjdk-17 غالباً، لكن نضبط JAVA_HOME
export JAVA_HOME=/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH
echo "✅ Java version: $(java -version 2>&1 | head -1)"

# 4. إضافة إعدادات خاصة بـ gradle.properties لمنع مشاكل AAPT2
echo "📝 Updating gradle.properties..."
cat >> android/gradle.properties << 'EOF'

# Fix AAPT2 issues
android.enableAapt2=false
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true
EOF

# 5. نسخ الملفات إلى www (نفس السكربت السابق)
echo "📁 Copying files to www..."
rm -rf www/
mkdir -p www
cp index.html www/
cp -r assets/ www/ 2>/dev/null
cp -r images/ www/ 2>/dev/null
cp -r scripts/ www/ 2>/dev/null
cp -r vendor/ www/ 2>/dev/null
cp *.js www/ 2>/dev/null
cp *.css www/ 2>/dev/null
echo "✅ Files copied."

# 6. نسخ إلى android
npx cap copy android

# 7. زيادة versionCode
VERSION_FILE="android/app/build.gradle"
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(grep -oP 'versionCode \K[0-9]+' "$VERSION_FILE")
    NEW=$((CURRENT + 1))
    sed -i "s/versionCode $CURRENT/versionCode $NEW/" "$VERSION_FILE"
    echo "✅ Version bumped: $CURRENT → $NEW"
fi

# 8. بناء APK مع --stacktrace لمعرفة أي خطأ آخر
echo "🛠️ Building APK (this will take 3-5 minutes)..."
cd android
./gradlew assembleDebug --stacktrace
if [ $? -ne 0 ]; then
    echo "❌ Build failed again. Trying with --no-daemon..."
    ./gradlew assembleDebug --no-daemon
    if [ $? -ne 0 ]; then
        echo "❌ Build still failing. See error above."
        cd ..
        exit 1
    fi
fi
cd ..

# 9. نسخ APK
APK_SOURCE="android/app/build/outputs/apk/debug/app-debug.apk"
APK_DEST="$HOME/Zarouali_Fixed.apk"
if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "$APK_DEST"
    echo "✅ APK saved at: $APK_DEST"
else
    echo "❌ APK not found!"
    exit 1
fi

# 10. تثبيت عبر ADB (اختياري)
if command -v adb &> /dev/null; then
    echo "📱 Installing APK..."
    PACKAGE=$(grep -E "appId" capacitor.config.ts | head -1 | sed -E "s/.*['\"]:?['\"]?([^'\"]+)['\"]?.*/\1/")
    [ ! -z "$PACKAGE" ] && adb uninstall "$PACKAGE" 2>/dev/null
    adb install -r "$APK_DEST"
    echo "✅ Installed."
else
    echo "⚠️ ADB not found. Copy $APK_DEST to phone and install manually."
fi

echo "=========================================="
echo "🎉 Done! Open the app. It should work now."
echo "=========================================="
