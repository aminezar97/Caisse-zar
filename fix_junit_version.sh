#!/data/data/com.termux/files/usr/bin/bash
# fix_junit_version.sh
# سكريبت لإصلاح مشكلة "Could not get unknown property 'junitVersion'"
# في مشاريع Capacitor/Android

set -e

# ===== إعدادات =====
PROJECT_DIR="$HOME/Caisse-zar"   # عدّل هذا المسار حسب مكان مشروعك في Termux
ANDROID_DIR="$PROJECT_DIR/android"
VARS_FILE="$ANDROID_DIR/variables.gradle"
APP_GRADLE="$ANDROID_DIR/app/build.gradle"
JUNIT_VERSION="4.13.2"

echo "==> التحقق من وجود المشروع..."
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ المجلد $PROJECT_DIR غير موجود. عدّل المتغير PROJECT_DIR في أعلى السكريبت."
    exit 1
fi

if [ ! -f "$VARS_FILE" ]; then
    echo "❌ الملف $VARS_FILE غير موجود."
    exit 1
fi

if [ ! -f "$APP_GRADLE" ]; then
    echo "❌ الملف $APP_GRADLE غير موجود."
    exit 1
fi

# ===== نسخ احتياطي =====
cp "$VARS_FILE" "$VARS_FILE.bak.$(date +%s)"
cp "$APP_GRADLE" "$APP_GRADLE.bak.$(date +%s)"
echo "==> تم أخذ نسخة احتياطية من الملفين."

# ===== 1) التحقق من junitVersion داخل variables.gradle =====
echo "==> التحقق من junitVersion في variables.gradle..."
if grep -q "junitVersion" "$VARS_FILE"; then
    echo "✅ junitVersion موجود مسبقًا في variables.gradle"
else
    echo "⚠️  junitVersion غير موجود، جاري الإضافة..."
    # إدراج السطر داخل أول كتلة ext { ... }
    if grep -q "ext[[:space:]]*{" "$VARS_FILE"; then
        sed -i "0,/ext[[:space:]]*{/s//ext {\n    junitVersion = '$JUNIT_VERSION'/" "$VARS_FILE"
        echo "✅ تمت إضافة junitVersion داخل كتلة ext الموجودة."
    else
        # إذا ما فيه كتلة ext أصلاً، أنشئ واحدة في نهاية الملف
        cat >> "$VARS_FILE" <<EOF

ext {
    junitVersion = '$JUNIT_VERSION'
}
EOF
        echo "✅ تم إنشاء كتلة ext جديدة وإضافة junitVersion."
    fi
fi

# ===== 2) التحقق من أن app/build.gradle يستدعي variables.gradle =====
echo "==> التحقق من استدعاء variables.gradle داخل app/build.gradle..."
if grep -q "apply from:.*variables.gradle" "$APP_GRADLE"; then
    echo "✅ app/build.gradle يستدعي variables.gradle مسبقًا."
else
    echo "⚠️  السطر غير موجود، جاري إضافته في أعلى الملف..."
    sed -i '1i apply from: "../variables.gradle"' "$APP_GRADLE"
    echo "✅ تمت إضافة apply from: \"../variables.gradle\""
fi

# ===== 3) طباعة السطر 43 الحالي للمراجعة =====
echo "==> السطر 43 الحالي في app/build.gradle:"
sed -n '43p' "$APP_GRADLE"

echo ""
echo "==> راجع السطر أعلاه: يجب أن يستخدم \$junitVersion هكذا:"
echo '    testImplementation "junit:junit:$junitVersion"'

# ===== 4) بناء المشروع للتأكد =====
echo ""
echo "==> هل تريد تجربة البناء الآن عبر gradlew؟ (y/n)"
read -r ANSWER
if [ "$ANSWER" = "y" ]; then
    cd "$ANDROID_DIR"
    chmod +x gradlew
    ./gradlew assembleDebug --stacktrace
fi

echo ""
echo "🎉 انتهى السكريبت. إذا استمرت المشكلة أرسل لي محتوى app/build.gradle و variables.gradle."
