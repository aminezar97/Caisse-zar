#!/bin/bash

echo "=========================================="
echo "    بدء تحديث أيقونة تطبيق Capacitor    "
echo "=========================================="

# 1. تثبيت الحزم البرمجية اللازمة في Termux لمعالجة الصور
echo "[1/4] جاري التحقق وتثبيت مكتبة libvips في Termux..."
pkg update -y && pkg install libvips nodejs -y

# 2. تثبيت الحزمة مع ضبط بيئة العمل لتفادي خطأ sharp
echo "[2/4] جاري تثبيت حزمة @capacitor/assets..."
npm install @capacitor/assets --save-dev --ignore-scripts=false

# 3. توليد الأيقونات الخاصة بالأندرويد من ملف icon.png
echo "[3/4] جاري توليد الأيقونات للشعار الخاص بك..."
npx capacitor-assets generate --android

# 4. مزامنة التغييرات مع مشروع أندرويد
echo "[4/4] جاري مزامنة الملفات مع أندرويد (Sync)..."
npx cap sync android

echo "=========================================="
echo "       تم الانتهاء بنجاح! شعارك جاهز      "
echo "=========================================="
