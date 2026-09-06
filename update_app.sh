#!/bin/bash

echo "==> 1. مزامنة وتحديث Capacitor لضمان جلب تعديلات index.html..."
npx cap sync android

echo "==> 2. إضافة التعديلات إلى Git..."
git add .

echo "==> 3. حفظ التغييرات (Commit)..."
git commit -m "Update: Apply latest changes to index.html and sync capacitor"

echo "==> 4. الرفع إلى GitHub لبدء بناء APK الجديد..."
git push origin main --force

echo "==> تم إرسال التحديثات بنجاح! 🚀"
echo "توجه إلى GitHub Actions وانتظر حتى ينتهي الـ Build ثم حمّل ملف APK الجديد."
