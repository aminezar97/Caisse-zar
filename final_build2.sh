#!/data/data/com.termux/files/usr/bin/bash

echo "=============================================="
echo "🔧 FINAL BUILD SCRIPT (Fixed JAVA_HOME & www)"
echo "=============================================="

# ==== 1. إصلاح JAVA_HOME تلقائياً ====
echo "🔍 Locating Java installation..."
JAVA_PATH=$(find /data/data/com.termux/files/usr -name "java" -type f 2>/dev/null | head -1)
if [ -z "$JAVA_PATH" ]; then
    echo "⚠️ Java not found in Termux. Please install: pkg install openjdk-17"
    exit 1
fi
JAVA_HOME=$(dirname $(dirname "$JAVA_PATH"))
export JAVA_HOME
export PATH=$JAVA_HOME/bin:$PATH
echo "✅ JAVA_HOME set to: $JAVA_HOME"
java -version 2>&1 | head -1

# ==== 2. إنشاء مجلد www ونسخ الملفات ====
echo "📁 Copying project files to www/ ..."
rm -rf www/
mkdir -p www

# نسخ كل الملفات والمجلدات المهمة
cp -f index.html www/ 2>/dev/null
if [ ! -f "www/index.html" ]; then
    echo "❌ index.html not found in project root! Aborting."
    exit 1
fi

# نسخ المجلدات
for folder in assets images scripts vendor css js; do
    if [ -d "$folder" ]; then
        cp -r "$folder" www/ 2>/dev/null
        echo "   Copied $folder"
    fi
done

# نسخ أي ملفات .js و .css في الجذر
cp -f *.js www/ 2>/dev/null
cp -f *.css www/ 2>/dev/null

echo "✅ Files copied. Contents of www/:"
ls -la www/

# ==== 3. نسخ إلى مشروع الأندرويد ====
echo "📦 Running npx cap copy android..."
npx cap copy android
if [ $? -ne 0 ]; then
    echo "❌ npx cap copy failed! Check if capacitor.config.ts is correct."
    exit 1
fi
echo "✅ Copy successful."

# ==== 4. زيادة versionCode ====
VERSION_FILE="android/app/build.gradle"
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(grep -oP 'versionCode \K[0-9]+' "$VERSION_FILE")
    NEW=$((CURRENT + 1))
    sed -i "s/versionCode $CURRENT/versionCode $NEW/" "$VERSION_FILE"
    echo "✅ Version bumped: $CURRENT → $NEW"
fi

# ==== 5. إضافة إعدادات لتجنب مشاكل AAPT2 ====
echo "📝 Tuning gradle.properties..."
cat >> android/gradle.properties << 'EOF'

# Fix for Termux
org.gradle.jvmargs=-Xmx
