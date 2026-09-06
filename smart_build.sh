#!/data/data/com.termux/files/usr/bin/bash

echo "=============================================="
echo "🧠 SMART BUILD SCRIPT (Auto-detects HTML)"
echo "=============================================="

# ==== 1. تأكد من أننا في المجلد الصحيح ====
echo "📂 Current directory: $(pwd)"
echo "📂 Contents of current directory:"
ls -la *.html *.htm 2>/dev/null || echo "   No .html/.htm files found in root!"

# ==== 2. البحث عن ملف HTML رئيسي ====
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
    # البحث عن أي ملف .html أو .htm في الجذر
    HTML_FILE=$(ls *.html *.htm 2>/dev/null | head -1)
fi

if [ -z "$HTML_FILE" ]; then
    echo "❌ No HTML file found! Create index.html or run:"
    echo "   echo '<h1>Hello</h1>' > index.html"
    exit 1
fi

echo "✅ Found HTML file: $HTML_FILE"

# ==== 3. إعداد مجلد www ====
echo "📁 Preparing www/ folder..."
rm -rf www/
mkdir -p www

# ==== 4. نسخ الملفات ====
echo "📄 Copying $HTML_FILE as index.html..."
cp "$HTML_FILE" www/index.html

echo "📁 Copying assets folders..."
for folder in assets images scripts vendor css js; do
    if [ -d "$folder" ]; then
        cp -r "$folder" www/ 2>/dev/null
        echo "   ✔ Copied $folder/"
    fi
done

echo "📄 Copying root JS/CSS files..."
cp -f *.js www/ 2>/dev/null
cp -f *.css www/ 2>/dev/null

echo "✅ www/ contents:"
ls -la www/

# ==== 5. إعداد JAVA_HOME (مكتشف تلقائي) ====
echo "☕ Setting up Java..."
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

# ==== 6. نسخ إلى مشروع الأندرويد ====
echo "📦 Running npx cap copy android..."
npx cap copy android
if [ $? -ne 0 ]; then
    echo "❌ npx cap copy failed! Check capacitor.config.ts"
    exit 1
fi
echo "✅ Copy successful."

# ==== 7. زيادة versionCode ====
VERSION_FILE="android/app/build.gradle"
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(grep -oP 'versionCode \K[0-9]+' "$VERSION_FILE")
    NEW=$((CURRENT + 1))
    sed -i "s/versionCode $CURRENT/versionCode $NEW/" "$VERSION_FILE"
    echo "✅ Version bumped: $CURRENT → $NEW"
fi

# ==== 8. تحسين gradle.properties ====
echo "📝 Optimizing gradle.properties..."
cat > android/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true
android.enableAapt2=false
EOF

# ==== 9. بناء APK ====
echo "🛠️ Building APK (this may take 3-5 minutes)..."
cd android
./gradlew assembleDebug --no-daemon
if [ $? -ne 0 ]; then
    echo "❌ Build failed. See error above."
    cd ..
    exit 1
fi
cd ..

# ==== 10. حفظ APK ====
APK_SOURCE="android/app/build/outputs/apk/debug/app-debug.apk"
APK_DEST="$HOME/Zarouali_Smart.apk"
if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "$APK_DEST"
    echo "✅ APK saved at: $APK_DEST"
    ls -lh "$APK_DEST"
else
    echo "❌ APK not found!"
    exit 1
fi

# ==== 11. (اختياري) تثبيت عبر ADB ====
if command -v adb &> /dev/null; then
    echo "📱 Installing via ADB..."
    PACKAGE=$(grep -E "appId" capacitor.config.ts | head -1 | sed -E "s/.*['\"]:?['\"]?([^'\"]+)['\"]?.*/\1/")
    if [ ! -z "$PACKAGE" ]; then
        adb uninstall "$PACKAGE" 2>/dev/null
    fi
    adb install -r "$APK_DEST"
    echo "✅ Installed."
else
    echo "⚠️ ADB not found. Copy $APK_DEST to phone and install manually."
fi

echo "=============================================="
echo "🎉 DONE! Your new APK is ready:"
echo "   📱 $APK_DEST"
echo "=============================================="
