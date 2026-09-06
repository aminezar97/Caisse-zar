#!/bin/bash

echo "==> الانتقال إلى مجلد www..."
cd www || { echo "مجلد www غير موجود!"; exit 1; }

echo "==> البحث عن الملف وتغيير اسمه إلى index.html..."
# التأكد من البحث عن أي ملف يبدأ بـ index ويحتوي على -4 أو صيغة شبيهة وتغييره إلى index.html
if [ -f "index-4.html" ]; then
    mv index-4.html index.html
    echo "تم تغيير اسم index-4.html إلى index.html بنجاح."
elif [ -f "index-4" ]; then
    mv index-4 index.html
    echo "تم تغيير اسم index-4 إلى index.html بنجاح."
else
    # إذا كان هناك ملف آخر، ابحث عن أي ملف شبيه
    for f in index*; do
        if [ "$f" != "index.html" ]; then
            mv "$f" index.html
            echo "تم تغيير اسم $f إلى index.html بنجاح."
            break
        fi
    done
fi

# العودة للمجلد الرئيسي للمشروع
cd ..

echo "==> مزامنة Capacitor وتحديث المشروع..."
npx cap sync android

echo "==> إضافة التعديلات إلى Git..."
git add .

echo "==> حفظ التغييرات (Commit)..."
git commit -m "Fix: Rename index-4 to index.html in www directory"

echo "==> الرفع إلى GitHub..."
git push origin main --force

echo "==> تم الانتهاء بنجاح! 🎉"
