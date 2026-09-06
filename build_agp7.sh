#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "🔧 BUILD WITH AGP 7.1.3 (Fix AAPT2)"
echo "=================================================="

# 1. البحث عن Java (حاول استخدام Java 11 إن وجد، وإلا Java 17)
echo "☕ Setting up Java..."
JAVA11_PATH=$(find /data/data/com.termux/files/usr -path "*/java-11-openjdk/bin/java" 2>/dev/null | head -1)
if [ -n "$JAVA11_PATH" ]; then
    JAVA_HOME=$(dirname $(dirname "$JAVA11_PATH"))
else
    JAVA17_PATH=$(find /data/data/com.termux/files/usr -name "java" -type f 2>/dev/null | head -1)
    if [ -z "$JAVA17_PATH" ]; then
        echo "❌ Java not found. Install: pkg install openjdk-17"
        exit 1
    fi
    JAVA_HOME=$(dirname $(dirname "$JAVA17_PATH"))
fi
export JAVA_HOME
export PATH=$JAVA_HOME/bin:$PATH
echo "✅ JAVA_HOME: $JAVA_HOME"
java -version 2>&1 | head -1

# 2. تنظيف الكاش بالكامل
echo "🧹 Cleaning all caches..."
rm -rf ~/.gradle/caches/
rm -rf android/.gradle/
rm -rf android/app/build/
rm -rf www/
echo "✅ Cache cleaned."

# 3. البحث عن ملف HTML
echo "🔍 Searching for HTML file..."
HTML_FILE=""
for f in index.html index.htm accueil.html accueil.htm; do
    [ -f "$f" ] && HTML_FILE="$f" && break
done
if [ -z "$HTML_FILE" ]; then
    HTML_FILE=$(ls *.html *.htm 2>/dev/null | head -1)
fi
if [ -z "$HTML_FILE" ]; then
    echo "❌ No HTML file. Create index.html"
    exit 1
fi
echo "✅ Using: $HTML_FILE"

# 4. نسخ الملفات إلى www
echo "📁 Copying to www..."
mkdir -p www
cp "$HTML_FILE" www/index.html
for d in assets images scripts vendor css js; do
    [ -d "$d" ] && cp -r "$d" www/
done
cp -f *.js *.css www/ 2>/dev/null
echo "✅ www ready."

# 5. نسخ إلى Android
npx cap copy android

# 6. تعديل إصدار AGP إلى 7.1.3
echo "📝 Downgrading AGP to 7.1.3..."
BUILD_GRADLE="android/build.gradle"
if [ -f "$BUILD_GRADLE" ]; then
    sed -i 's/classpath("com.android.tools.build:gradle:[^"]*")/classpath("com.android.tools.build:gradle:7.1.3")/g' "$BUILD_GRADLE"
    sed -i "s/classpath 'com.android.tools.build:gradle:[^']*'/classpath 'com.android.tools.build:gradle:7.1.3'/g" "$BUILD_GRADLE"
    echo "✅ AGP set to 7.1.3"
fi

# 7. تعديل Gradle Wrapper إلى 7.5
WRAPPER="android/gradle/wrapper/gradle-wrapper.properties"
if [ -f "$WRAPPER" ]; then
    sed -i 's/gradle-[0-9.]*-all.zip/gradle-7.5-all.zip/g' "$WRAPPER"
    sed -i 's/gradle-[0-9.]*-bin.zip/gradle-7.5-bin.zip/g' "$WRAPPER"
    echo "✅ Gradle set to 7.5"
fi

# 8. كتابة gradle.properties (مع enableAapt2=false)
echo "📝 Writing gradle.properties..."
cat > android/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true
android.enableAapt2=false
EOF

# 9. زيادة versionCode
VERSION_FILE="android/app/build.gradle"
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(grep -oP 'versionCode \K[0-9]+' "$VERSION_FILE")
    NEW=$((CURRENT + 1))
    sed -i "s/versionCode $CURRENT/versionCode $NEW/" "$VERSION_FILE"
    echo "✅ Version bumped: $CURRENT → $NEW"
fi

# 10. بناء APK مع --no-daemon و --max-workers=1
echo "🛠️ Building APK (may take 5-7 minutes)..."
cd android
./gradlew assembleDebug --no-daemon --max-workers=1
if [ $? -ne 0 ]; then
    echo "❌ Build failed. Trying with --stacktrace..."
    ./gradlew assembleDebug --no-daemon --stacktrace
    if [ $? -ne 0 ]; then
        echo "❌ Build still failing. See error above."
        cd ..
        exit 1
    fi
fi
cd ..

# 11. نسخ APK
APK_SOURCE="android/app/build/outputs/apk/debug/app-debug.apk"
APK_DEST="$HOME/Zarouali_AGP7.apk"
if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "$APK_DEST"
    echo "✅ APK saved: $APK_DEST"
    ls -lh "$APK_DEST"
else
    echo "❌ APK not found."
    exit 1
fi

# 12. تثبيت عبر ADB
if command -v adb &> /dev/null; then
    echo "📱 Installing..."
    PACKAGE=$(grep -E "appId" capacitor.config.ts | head -1 | sed -E "s/.*['\"]:?['\"]?([^'\"]+)['\"]?.*/\1/")
    [ -n "$PACKAGE" ] && adb uninstall "$PACKAGE" 2>/dev/null
    adb install -r "$APK_DEST"
    echo "✅ Installed."
else
    echo "⚠️ ADB not found. Copy $APK_DEST to phone manually."
fi

echo "=================================================="
echo "🎉 SUCCESS! Your APK is ready:"
echo "   📱 $APK_DEST"
echo "=================================================="
