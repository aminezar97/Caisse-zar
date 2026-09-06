#!/bin/bash

# 1. تحديد مسار المصدر (المجلد الموجود في الهاتف)
SOURCE_DIR="$HOME/storage/shared/Alarms/zarouali_caisse_images_fixed"

echo "==> جاري التحقق من وجود الملفات..."
if [ ! -d "$SOURCE_DIR" ]; then
    echo "خطأ: مسار الملفات غير موجود! تأكد من منح صلاحيات التخزين عبر أمر termux-setup-storage"
    exit 1
fi

echo "==> جاري نسخ الصور والملفات إلى مجلد المشروع الحالي..."
cp -r "$SOURCE_DIR"/* .

echo "==> جاري إضافة الملفات والمجلدات إلى نظام Git..."
git add .

echo "==> جاري حفظ التغييرات (Commit)..."
git commit -m "Auto-upload: Add images, README and CSV files from Alarms folder"

echo "==> جاري الرفع إلى GitHub (Push)..."
git push origin main

echo "==> تم الرفع بنجاح! 🎉"

