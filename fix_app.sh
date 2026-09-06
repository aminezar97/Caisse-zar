#!/data/data/com.termux/files/usr/bin/bash

echo "=============================="
echo "🔧 Capacitor Fix Script for Termux"
echo "=============================="

# 1. إيقاف أي خادم قديم (Node.js / http-server)
echo "🛑 Stopping old servers..."
pkill -f "npm run" 2>/dev/null
pkill -f "http-server" 2>/dev/null
pkill -f "node.*serve" 2>/dev/null
pkill -f "vite" 2>/dev/null
echo "✅ Done."

# 2. حذف مجلدات البناء القديمة (للتخلص من الكاش نهائياً)
echo "🗑️ Removing old www / dist folders..."
rm -rf www/ 2>/dev/null
rm -rf dist/ 2>/dev/null
rm -rf .vite/ 2>/dev/null
echo "✅ Done."

# 3. إعادة بناء المشروع (افتراضي Vue/React/Angular)
echo "📦 Running npm run build..."
npm run build

# تحقق من نجاح البناء
if [ $? -ne 0 ]; then
    echo "❌ Build failed! Fix errors and try again."
    exit 1
fi
echo "✅ Build successful."

# 4. نسخ الملفات الجديدة إلى مجلد Android
echo "📁 Copying to android (npx cap copy)..."
npx cap copy android

# في حال أضفت مكتبات جديدة، استخدم sync بدلاً من copy
# npx cap sync android

echo "✅ Copy done."

# 5. محاولة مسح كاش التطبيق عبر ADB (إذا كان الهاتف متصلاً بالكمبيوتر)
if command -v adb &> /dev/null; then
    echo "📱 Searching for app package name..."
    # استخراج اسم الحزمة من capacitor.config.ts
    PACKAGE_NAME=$(grep -E "appId|appId:" capacitor.config.ts | head -1 | sed -E "s/.*['\"]:?['\"]?([^'\"]+)['\"]?.*/\1/")
    
    if [ ! -z "$PACKAGE_NAME" ]; then
        echo "Clearing cache for $PACKAGE_NAME..."
        adb shell pm clear $PACKAGE_NAME 2>/dev/null
        echo "✅ Cache cleared (if app was installed)."
    else
        echo "⚠️ Could not detect package. Clear cache manually."
    fi
else
    echo "⚠️ ADB not found. Clear cache manually from phone settings."
fi

echo "=============================="
echo "✅ Script finished!"
echo "📌 IMPORTANT:"
echo "  - If you use a live server, restart it: npm run serve"
echo "  - If you build APK, rebuild it or reinstall the app."
echo "  - If the old version persists: Go to Settings > Apps > [Your App] > Clear Storage."
echo "=============================="
