#!/bin/bash

# إنشاء مجلد مؤقت محلي لتجنب مشاكل الصلاحيات في /tmp
mkdir -p temp_extracted

# فك ضغط الملف من مجلد التخزين
unzip ~/storage/downloads/new_images.zip -d temp_extracted

# التأكد من وجود مجلد الوجهة ونقل الصور إليه
mkdir -p www/images
cp -r temp_extracted/images/* www/images/

# تنظيف المجلد المؤقت
rm -rf temp_extracted

echo "تم استخراج ونقل الصور بنجاح!"
