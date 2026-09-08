#!/bin/bash

# 1. التأكد من التواجد في مجلد المشروع الرئيسي
cd ~/Caisse-zar || exit

echo "-> تنظيف المجلدات المؤقتة القديمة..."
rm -rf temp_extracted

# 2. إنشاء مجلد مؤقت وفك ضغط الملف الجديد
echo "-> جاري فك ضغط الملف الجديد..."
mkdir -p temp_extracted
unzip -o ~/storage/downloads/new_images.zip -d temp_extracted

# 3. حذف مجلد الصور القديم بالكامل واستبداله بالجديد
echo "-> استبدال مجلد الصور القديم بالجديد..."
rm -rf www/images
mkdir -p www/images
cp -r temp_extracted/images/* www/images/

# 4. تنظيف الملفات المؤقتة
rm -rf temp_extracted

echo "-> تجهيز التعديلات لرفعها إلى GitHub..."
git add www/images

# 5. عمل Commit و Push للمستودع
git commit -m "Update images folder with new dataset"
git push origin main

echo "تم تحديث الصور ورفعها إلى GitHub بنجاح!"
