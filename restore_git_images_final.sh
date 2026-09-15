#!/data/data/com.termux/files/usr/bin/bash

set -e

cd "$HOME/Caisse-zar"

REPORT="reports/git_real_image_versions.csv"
IMG_DIR="www/images"
BACKUP="backups/before-git-image-restore-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

echo "======================================================"
echo " ZAROUALI CAISSE"
echo " FINAL GIT IMAGE RESTORE"
echo "======================================================"
echo
echo "Backup: $BACKUP"
echo

restored=0
failed=0
skipped=0

while IFS=';' read -r image commit size; do

    # تجاهل header
    [ "$image" = "image" ] && continue
    [ -z "$image" ] && continue

    target="$IMG_DIR/$image"

    echo "Processing: $image"

    # لا نكتب فوق صورة موجودة
    if [ -s "$target" ]; then
        echo "  SKIP - already exists"
        skipped=$((skipped+1))
        continue
    fi

    # تحقق أن النسخة موجودة فعلاً داخل commit
    if ! git cat-file -e "$commit:www/images/$image" 2>/dev/null; then
        echo "  FAILED - file not found in commit"
        failed=$((failed+1))
        continue
    fi

    # استخراج الصورة
    git show "$commit:www/images/$image" > "$target"

    # تحقق من الحجم
    actual_size=$(wc -c < "$target")

    if [ "$actual_size" -gt 0 ]; then
        echo "  RESTORED - $actual_size bytes"
        restored=$((restored+1))
    else
        echo "  FAILED - empty file"
        rm -f "$target"
        failed=$((failed+1))
    fi

done < "$REPORT"

echo
echo "======================================================"
echo " RESTORE RESULT"
echo "======================================================"
echo "Restored : $restored"
echo "Skipped  : $skipped"
echo "Failed   : $failed"
echo

echo "======================================================"
echo " VERIFYING FILES"
echo "======================================================"

python - <<'PY'
import csv
import os
import imghdr

report = "reports/git_real_image_versions.csv"
img_dir = "www/images"

valid = 0
invalid = 0
missing = 0

with open(report, encoding="utf-8-sig") as f:
    rows = list(csv.DictReader(f, delimiter=";"))

for row in rows:
    image = row["image"]
    path = os.path.join(img_dir, image)

    if not os.path.isfile(path):
        print("MISSING:", image)
        missing += 1
        continue

    kind = imghdr.what(path)

    if kind:
        valid += 1
    else:
        print("INVALID:", image)
        invalid += 1

print()
print("======================================================")
print(" VERIFICATION")
print("======================================================")
print("Valid   :", valid)
print("Invalid :", invalid)
print("Missing :", missing)
PY

echo
echo "======================================================"
echo " DONE"
echo "======================================================"
echo
echo "لم يتم تنفيذ git push."
echo
