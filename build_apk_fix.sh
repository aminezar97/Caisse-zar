#!/data/data/com.termux/files/usr/bin/bash

echo "============================================="
echo "📦 Building APK (Static HTML project)"
echo "============================================="

# 1. حذف www القديم وإنشاؤه من جديد
echo "🗑️ Cleaning www folder..."
rm -rf www/
mkdir -p www

# 2. نسخ جميع ملفات HTML و HTM و CSS و JS و assets إلى www
echo "📁 Copying static files to www/ ..."
cp -r ./*.html www/ 2>/dev/null
cp -r ./*.htm www/ 2>/dev/null
cp -r ./assets/ www/ 2>/dev/null
cp -r ./css/ www/ 2>/dev/null
cp -r ./js/ www/ 2>/dev/null
cp -r ./*.js www/ 2>/dev/null
cp -r ./*.css www/ 2>/dev/null

# 3. التأكد من وجود index.html (إذا كان الملف الرئيسي يحمل اسماً آخر)
if [ ! -f "www/index.html" ]; then
    # ابحث عن أي ملف .htm أو .html
    MAIN_FILE=$(ls www/*.htm 2>/dev/null | head -1)
    if [ -z "$MAIN_FILE" ]; then
        MAIN_FILE=$(ls www/*.html 2>/dev/null | head -1)
    fi
    if [ ! -z "$MAIN_FILE" ]; then
        echo "📄 Renaming $MAIN_FILE to index.html ..."
        mv "$MAIN_FILE" www/index.html
    else
        echo "❌ No HTML file found in project! Please create an index.html or index.htm."
        exit 1
    fi
fi

# 4. نسخ الملفات إلى android عبر Capacitor
echo "📁 Copying to android (npx cap copy)..."
npx cap copy android
if [ $? -ne 0 ]; then
    echo "❌ npx cap copy failed!"
    exit 1
fi
echo "✅ Copy successful."

# 5. زيادة versionCode لمسح الكاش
echo "🔢 Incrementing version code..."
VERSION_FILE="android/app/build.gradle"
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(grep -oP 'versionCode \K[0-9]+' "$VERSION_FILE")
    NEW=$((CURRENT + 1))
    sed -i "s/versionCode $CURRENT/versionCode $NEW/" "$VERSION_FILE"
    echo "✅ Version code updated: $CURRENT → $NEW"
fi

# 6. بناء APK
echo "🛠️ Building APK (this may take 2-4 minutes)..."
cd android
./gradlew assembleDebug
if [ $? -ne 0 ]; then
    echo "❌ Gradle build failed."
    cd ..
    exit 1
fi
cd ..

# 7. نسخ APK إلى مكان واضح
APK_SOURCE="android/app/build/outputs/apk/debug/app-debug.apk"
APK_DEST="$HOME/Zarouali_POS_Fixed.apk"
if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "$APK_DEST"
    echo "✅ New APK saved at: $APK_DEST"
else
    echo "❌ APK not found! Check build output."
    exit 1
fi

# 8. (اختياري) تثبيت عبر ADB إذا كان الهاتف موصولاً
if command -v adb &> /dev/null; then
    echo "📱 Installing via ADB (uninstalling old first)..."
    PACKAGE=$(grep -E "appId" capacitor.config.ts | head -1 | sed -E "s/.*['\"]:?['\"]?([^'\"]+)['\"]?.*/\1/")
    if [ ! -z "$PACKAGE" ]; then
        adb uninstall "$PACKAGE" 2>/dev/null
    fi
    adb install -r "$APK_DEST"
    echo "✅ Installed."
else
    echo "⚠️ ADB not found. Transfer $APK_DEST to your phone manually."
fi

echo "============================================="
echo "✅ APK built successfully!"
echo "📌 Install the new APK and the old version will be replaced."
echo "============================================="
