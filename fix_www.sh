#!/bin/bash

echo "==> 1. إنشاء مجلد www ونقل ملف index.html إليه..."
mkdir -p www
if [ -f "index.html" ]; then
    mv index.html www/
fi

echo "==> 2. تحديث ومزامنة Capacitor مع أندرويد..."
npx cap sync android

echo "==> 3. إضافة التعديلات إلى Git..."
git add .

echo "==> 4. حفظ التغييرات (Commit)..."
git commit -m "Fix: Move index.html into www and sync capacitor"

echo "==> 5. الرفع إلى GitHub..."
git push origin main --force

echo "==> تم الانتهاء بنجاح! 🎉"
