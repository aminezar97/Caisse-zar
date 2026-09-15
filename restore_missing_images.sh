#!/data/data/com.termux/files/usr/bin/bash

set -e

ROOT="$HOME/Caisse-zar"
cd "$ROOT"

CSV="reports/missing_images.csv"
IMG_DIR="www/images"
BACKUP="backups/restore-images-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BACKUP"

echo "======================================================"
echo " ZAROUALI CAISSE - RESTORE MISSING IMAGES"
echo "======================================================"
echo

if [ ! -f "$CSV" ]; then
    echo "ERROR: $CSV غير موجود"
    exit 1
fi

echo "Backup directory:"
echo "$BACKUP"
echo

restored=0
failed=0
already=0

while IFS=';' read -r id name image; do

    # تجاهل Header
    [ "$id" = "id" ] && continue
    [ -z "$image" ] && continue

    target="$IMG_DIR/$image"

    # إذا الصورة موجودة فعلاً، لا نلمسها
    if [ -s "$target" ]; then
        echo "SKIP      $image  (already exists)"
        already=$((already+1))
        continue
    fi

    echo
    echo "Searching Git history for: $image"

    found_commit=""

    # كل الـ commits التي تعاملت مع هذا الملف
    commits=$(git rev-list --all -- "www/images/$image" 2>/dev/null || true)

    for commit in $commits; do
        if git cat-file -e "$commit:www/images/$image" 2>/dev/null; then
            found_commit="$commit"
            break
        fi
    done

    if [ -z "$found_commit" ]; then
        echo "FAILED    $image"
        failed=$((failed+1))
        continue
    fi

    # حفظ أي ملف مفترض موجود قبل الاسترجاع
    if [ -e "$target" ]; then
        mkdir -p "$BACKUP"
        cp -p "$target" "$BACKUP/$image"
    fi

    # استرجاع الملف فقط
    mkdir -p "$IMG_DIR"

    git show "$found_commit:www/images/$image" > "$target"

    # تحقق من أن الملف غير فارغ
    if [ -s "$target" ]; then
        size=$(wc -c < "$target")
        echo "RESTORED  $image  <- ${found_commit:0:12}  (${size} bytes)"
        restored=$((restored+1))
    else
        echo "FAILED    $image  (empty file)"
        rm -f "$target"
        failed=$((failed+1))
    fi

done < "$CSV"

echo
echo "======================================================"
echo " RESULT"
echo "======================================================"
echo "Restored : $restored"
echo "Already  : $already"
echo "Failed   : $failed"
echo
echo "Backup:"
echo "$BACKUP"
echo

echo "Checking restored images..."
echo

python - <<'PY'
import csv
import os
from PIL import Image

csv_file = "reports/missing_images.csv"
img_dir = "www/images"

ok = 0
bad = 0
missing = 0

with open(csv_file, encoding="utf-8-sig") as f:
    rows = list(csv.DictReader(f, delimiter=";"))

for row in rows:
    filename = row["image"]
    path = os.path.join(img_dir, filename)

    if not os.path.isfile(path):
        print("MISSING:", filename)
        missing += 1
        continue

    try:
        with Image.open(path) as im:
            im.verify()
        ok += 1
    except Exception as e:
        print("BAD:", filename, e)
        bad += 1

print()
print("======================================================")
print(" IMAGE VALIDATION")
print("======================================================")
print("Valid images :", ok)
print("Bad images   :", bad)
print("Missing      :", missing)
PY

echo
echo "======================================================"
echo " DONE"
echo "======================================================"
echo
echo "لم يتم تنفيذ git push."
echo
