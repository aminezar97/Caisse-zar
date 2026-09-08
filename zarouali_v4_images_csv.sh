#!/data/data/com.termux/files/usr/bin/bash

set -e

PROJECT="$HOME/Caisse-zar"
CSV="$PROJECT/www/data/products.csv"
IMG="$PROJECT/www/images"

REPORT="$PROJECT/reports"
BACKUP="$PROJECT/backups/v4-$(date +%Y%m%d-%H%M%S)"

echo "================================================"
echo "       ZAROUALI CAISSE V4.1"
echo "   IMAGE + CSV + BARCODE + PRICE SYSTEM"
echo "================================================"

cd "$PROJECT"

mkdir -p "$REPORT"
mkdir -p "$BACKUP"
mkdir -p "$IMG/_unmatched"
mkdir -p "$IMG/_duplicates"
mkdir -p "$IMG/_invalid"

# ------------------------------------------------
# 1. Backup
# ------------------------------------------------

echo
echo "[1/10] Backup..."

cp "$CSV" "$BACKUP/products.csv" 2>/dev/null || true

# لا ننسخ الصور كاملة إذا كانت كثيرة
find "$IMG" -maxdepth 1 -type f \
    > "$BACKUP/image-list.txt" || true

# ------------------------------------------------
# 2. Python processor
# ------------------------------------------------

echo "[2/10] Processing CSV and images..."

cat > .tmp/zarouali_v4.py <<'PY'

import csv
import os
import re
import shutil
import hashlib
from collections import defaultdict

BASE = os.path.expanduser("~/Caisse-zar")

CSV_FILE = BASE + "/www/data/products.csv"
IMG_DIR = BASE + "/www/images"
REPORT = BASE + "/reports"

os.makedirs(REPORT, exist_ok=True)

# ------------------------------------------------
# Helpers
# ------------------------------------------------

def clean(value):
    if value is None:
        return ""
    return str(value).strip()

def normalize_name(value):
    value = clean(value).lower()

    value = value.replace("é","e")
    value = value.replace("è","e")
    value = value.replace("ê","e")
    value = value.replace("à","a")
    value = value.replace("â","a")
    value = value.replace("ù","u")
    value = value.replace("û","u")
    value = value.replace("ô","o")
    value = value.replace("î","i")
    value = value.replace("ï","i")

    value = re.sub(r"[^a-z0-9]+", " ", value)

    return " ".join(value.split())

def number(value):
    value = clean(value)
    value = value.replace(",", ".")

    try:
        return float(value)
    except:
        return 0.0

def image_hash(path):
    try:
        h = hashlib.sha256()

        with open(path, "rb") as f:
            while True:
                block = f.read(1024 * 1024)

                if not block:
                    break

                h.update(block)

        return h.hexdigest()

    except:
        return None

# ------------------------------------------------
# Read CSV
# ------------------------------------------------

if not os.path.exists(CSV_FILE):

    print("ERROR: products.csv not found")
    raise SystemExit(1)

with open(
    CSV_FILE,
    encoding="utf-8-sig",
    errors="replace"
) as f:

    sample = f.read(10000)

delimiter = ";" if sample.count(";") >= sample.count(",") else ","

with open(
    CSV_FILE,
    encoding="utf-8-sig",
    errors="replace",
    newline=""
) as f:

    reader = csv.DictReader(
        f,
        delimiter=delimiter
    )

    raw = list(reader)

# ------------------------------------------------
# Convert products
# ------------------------------------------------

products = []

for index, row in enumerate(raw, 1):

    r = {
        clean(k).lower(): clean(v)
        for k,v in row.items()
    }

    def get(*keys):

        for key in keys:

            if key in r and r[key]:
                return r[key]

        return ""

    pid = get(
        "id",
        "product_id",
        "code"
    )

    name = get(
        "name",
        "product",
        "product_name",
        "nom"
    )

    category = get(
        "category",
        "categorie",
        "catégorie"
    )

    barcode = get(
        "barcode",
        "bar_code",
        "ean",
        "codebarre"
    )

    price = number(
        get(
            "price",
            "prix",
            "saleprice",
            "sellingprice"
        )
    )

    purchase = number(
        get(
            "purchaseprice",
            "purchase_price",
            "prixachat",
            "cost"
        )
    )

    stock = number(
        get(
            "stock",
            "quantity",
            "qty"
        )
    )

    minstock = number(
        get(
            "minstock",
            "min_stock",
            "minimum"
        )
    )

    image = get(
        "image",
        "photo",
        "picture",
        "img"
    )

    if not pid:
        pid = str(index)

    if not name:
        name = "Produit " + pid

    if not category:
        category = "Autres"

    if not image:
        image = pid + ".jpg"

    image = os.path.basename(image)

    products.append({
        "id": pid,
        "name": name,
        "category": category,
        "barcode": barcode,
        "price": f"{price:.2f}",
        "purchasePrice": f"{purchase:.2f}",
        "stock": int(stock) if stock.is_integer() else stock,
        "minStock": int(minstock) if minstock.is_integer() else minstock,
        "image": image
    })

# ------------------------------------------------
# Remove duplicate IDs
# ------------------------------------------------

seen = set()
clean_products = []

duplicate_ids = []

for p in products:

    if p["id"] in seen:

        duplicate_ids.append(p)
        continue

    seen.add(p["id"])

    clean_products.append(p)

products = clean_products

# ------------------------------------------------
# Detect duplicate barcodes
# ------------------------------------------------

barcode_map = defaultdict(list)

for p in products:

    barcode = p["barcode"]

    if barcode:
        barcode_map[barcode].append(p["id"])

duplicate_barcodes = {
    k:v
    for k,v in barcode_map.items()
    if len(v) > 1
}

# ------------------------------------------------
# Image inventory
# ------------------------------------------------

image_files = []

for root, dirs, files in os.walk(IMG_DIR):

    for filename in files:

        if filename.startswith("."):
            continue

        if filename.startswith("_"):
            continue

        ext = os.path.splitext(filename)[1].lower()

        if ext in (
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        ):

            image_files.append(
                os.path.join(root, filename)
            )

# ------------------------------------------------
# Build image lookup
# ------------------------------------------------

by_filename = {}
by_stem = defaultdict(list)

for path in image_files:

    filename = os.path.basename(path)

    stem = os.path.splitext(filename)[0]

    by_filename[filename.lower()] = path

    by_stem[stem.lower()].append(path)

# ------------------------------------------------
# Match images
# ------------------------------------------------

matched = []
missing = []
ambiguous = []

for p in products:

    pid = str(p["id"])

    current = p["image"]

    candidates = []

    # 1 filename from CSV
    if current:

        path = by_filename.get(
            current.lower()
        )

        if path:
            candidates.append(path)

    # 2 ID.jpg
    for ext in (
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ):

        path = by_filename.get(
            (pid + ext).lower()
        )

        if path:
            candidates.append(path)

    # Remove duplicates
    candidates = list(dict.fromkeys(candidates))

    if len(candidates) == 1:

        source = candidates[0]

        destination = os.path.join(
            IMG_DIR,
            pid + ".jpg"
        )

        matched.append(
            (p, source, destination)
        )

    elif len(candidates) > 1:

        ambiguous.append(
            (p, candidates)
        )

    else:

        missing.append(p)

# ------------------------------------------------
# Copy / rename images
# ------------------------------------------------

converted = 0

for p, source, destination in matched:

    try:

        if os.path.abspath(source) == os.path.abspath(destination):

            pass

        else:

            # إذا destination موجود لا نحذفه
            if not os.path.exists(destination):

                shutil.copy2(
                    source,
                    destination
                )

        p["image"] = pid = str(p["id"]) + ".jpg"

        converted += 1

    except Exception as e:

        print(
            "Image error:",
            p["id"],
            e
        )

# ------------------------------------------------
# Save missing images
# ------------------------------------------------

with open(
    REPORT + "/missing_images.csv",
    "w",
    encoding="utf-8",
    newline=""
) as f:

    writer = csv.DictWriter(
        f,
        fieldnames=[
            "id",
            "name",
            "image"
        ],
        delimiter=";"
    )

    writer.writeheader()

    for p in missing:

        writer.writerow({
            "id": p["id"],
            "name": p["name"],
            "image": p["image"]
        })

# ------------------------------------------------
# Ambiguous images
# ------------------------------------------------

with open(
    REPORT + "/ambiguous_images.csv",
    "w",
    encoding="utf-8",
    newline=""
) as f:

    writer = csv.writer(
        f,
        delimiter=";"
    )

    writer.writerow([
        "id",
        "name",
        "candidates"
    ])

    for p, candidates in ambiguous:

        writer.writerow([
            p["id"],
            p["name"],
            "|".join(candidates)
        ])

# ------------------------------------------------
# Zero prices
# ------------------------------------------------

with open(
    REPORT + "/zero_prices.csv",
    "w",
    encoding="utf-8",
    newline=""
) as f:

    writer = csv.DictWriter(
        f,
        fieldnames=[
            "id",
            "name",
            "barcode",
            "price"
        ],
        delimiter=";"
    )

    writer.writeheader()

    for p in products:

        if float(p["price"]) <= 0:

            writer.writerow({
                "id": p["id"],
                "name": p["name"],
                "barcode": p["barcode"],
                "price": p["price"]
            })

# ------------------------------------------------
# Missing barcodes
# ------------------------------------------------

with open(
    REPORT + "/missing_barcodes.csv",
    "w",
    encoding="utf-8",
    newline=""
) as f:

    writer = csv.DictWriter(
        f,
        fieldnames=[
            "id",
            "name",
            "image"
        ],
        delimiter=";"
    )

    writer.writeheader()

    for p in products:

        if not p["barcode"]:

            writer.writerow({
                "id": p["id"],
                "name": p["name"],
                "image": p["image"]
            })

# ------------------------------------------------
# Duplicate barcodes
# ------------------------------------------------

with open(
    REPORT + "/duplicate_barcodes.csv",
    "w",
    encoding="utf-8",
    newline=""
) as f:

    writer = csv.writer(
        f,
        delimiter=";"
    )

    writer.writerow([
        "barcode",
        "product_ids"
    ])

    for barcode, ids in duplicate_barcodes.items():

        writer.writerow([
            barcode,
            ",".join(ids)
        ])

# ------------------------------------------------
# Write FINAL CSV
# ------------------------------------------------

FINAL = CSV_FILE

with open(
    FINAL,
    "w",
    encoding="utf-8-sig",
    newline=""
) as f:

    fields = [
        "id",
        "name",
        "category",
        "barcode",
        "price",
        "purchasePrice",
        "stock",
        "minStock",
        "image"
    ]

    writer = csv.DictWriter(
        f,
        fieldnames=fields,
        delimiter=";"
    )

    writer.writeheader()

    for p in products:

        writer.writerow(p)

# ------------------------------------------------
# Image duplicate detection
# ------------------------------------------------

hashes = defaultdict(list)

for path in image_files:

    h = image_hash(path)

    if h:
        hashes[h].append(path)

duplicate_images = [
    paths
    for paths in hashes.values()
    if len(paths) > 1
]

with open(
    REPORT + "/duplicate_images.txt",
    "w",
    encoding="utf-8"
) as f:

    for group in duplicate_images:

        f.write(
            "\n".join(group)
        )

        f.write("\n\n")

# ------------------------------------------------
# Summary
# ------------------------------------------------

print()
print("==============================================")
print("             FINAL RESULT")
print("==============================================")
print("Products              :", len(products))
print("Images found          :", len(image_files))
print("Images matched        :", len(matched))
print("Images missing        :", len(missing))
print("Ambiguous images      :", len(ambiguous))
print("Zero prices           :", sum(
    float(p["price"]) <= 0
    for p in products
))
print("Missing barcodes      :", sum(
    not p["barcode"]
    for p in products
))
print("Duplicate barcodes    :", len(
    duplicate_barcodes
))
print("Duplicate image sets  :", len(
    duplicate_images
))
print("==============================================")

PY

python .tmp/zarouali_v4.py

# ------------------------------------------------
# 3. Product checker
# ------------------------------------------------

echo
echo "[3/10] Creating checker..."

cat > check-zarouali.sh <<'EOF2'
#!/data/data/com.termux/files/usr/bin/bash

echo "=========================================="
echo "        ZAROUALI CAISSE CHECK"
echo "=========================================="

echo
echo "CSV lines:"
wc -l www/data/products.csv

echo
echo "Images:"
find www/images -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    | wc -l

echo
echo "Missing images:"
tail -n +2 reports/missing_images.csv 2>/dev/null | wc -l

echo
echo "Zero prices:"
tail -n +2 reports/zero_prices.csv 2>/dev/null | wc -l

echo
echo "Missing barcodes:"
tail -n +2 reports/missing_barcodes.csv 2>/dev/null | wc -l

echo
echo "Duplicate barcodes:"
tail -n +2 reports/duplicate_barcodes.csv 2>/dev/null | wc -l

echo
echo "=========================================="
EOF2

chmod +x check-zarouali.sh

# ------------------------------------------------
# 4. Check CSV image references
# ------------------------------------------------

echo
echo "[4/10] Verifying CSV image references..."

python - <<'PY'
import csv
import os

csv_file = "www/data/products.csv"
img_dir = "www/images"

bad = []

with open(csv_file, encoding="utf-8-sig") as f:

    reader = csv.DictReader(f, delimiter=";")

    for row in reader:

        image = row.get("image","").strip()

        if not image:
            bad.append(row)
            continue

        path = os.path.join(
            img_dir,
            os.path.basename(image)
        )

        if not os.path.isfile(path):
            bad.append(row)

print("Invalid image references:", len(bad))

with open(
    "reports/final_image_errors.csv",
    "w",
    encoding="utf-8",
    newline=""
) as f:

    writer = csv.writer(
        f,
        delimiter=";"
    )

    writer.writerow([
        "id",
        "name",
        "image"
    ])

    for row in bad:

        writer.writerow([
            row.get("id",""),
            row.get("name",""),
            row.get("image","")
        ])
PY

# ------------------------------------------------
# 5. Generate JS image helper
# ------------------------------------------------

echo
echo "[5/10] Creating image helper..."

cat > www/js/product-images.js <<'EOF3'
window.ZaroualiProductImages = {

    get(product) {

        if (!product) {
            return "./images/placeholder.jpg";
        }

        const id = String(
            product.id || ""
        ).trim();

        const image = String(
            product.image || ""
        ).trim();

        if (image) {

            if (
                image.startsWith("./") ||
                image.startsWith("images/")
            ) {
                return image.startsWith("./")
                    ? image
                    : "./" + image;
            }

            return "./images/" + image;
        }

        if (id) {
            return "./images/" + id + ".jpg";
        }

        return "./images/placeholder.jpg";
    }

};
EOF3

# ------------------------------------------------
# 6. Generate placeholder
# ------------------------------------------------

echo
echo "[6/10] Creating placeholder..."

python - <<'PY'
from pathlib import Path

p = Path("www/images/placeholder.svg")

p.write_text(
'''<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500">
<rect width="100%" height="100%" fill="#f2f2f2"/>
<text x="50%" y="50%" text-anchor="middle"
font-family="Arial" font-size="30" fill="#777">
No Image
</text>
</svg>''',
encoding="utf-8"
)

PY

# ------------------------------------------------
# 7. Update manifest if present
# ------------------------------------------------

echo
echo "[7/10] Checking manifest..."

if [ -f "www/manifest.webmanifest" ]; then

    python - <<'PY'
import json

file = "www/manifest.webmanifest"

try:

    with open(file, encoding="utf-8") as f:
        data = json.load(f)

    data["name"] = "Zarouali Caisse"
    data["short_name"] = "Zarouali Caisse"
    data["start_url"] = "./"
    data["display"] = "standalone"

    with open(file, "w", encoding="utf-8") as f:
        json.dump(
            data,
            f,
            indent=2,
            ensure_ascii=False
        )

except Exception as e:

    print("Manifest warning:", e)

PY

fi

# ------------------------------------------------
# 8. Search dangerous hardcoded password
# ------------------------------------------------

echo
echo "[8/10] Security audit..."

grep -Rni \
    '1234' \
    www \
    > reports/password-audit.txt \
    || true

# ------------------------------------------------
# 9. Git status
# ------------------------------------------------

echo
echo "[9/10] Git status..."

git status --short

# ------------------------------------------------
# 10. Final check
# ------------------------------------------------

echo
echo "[10/10] Final diagnostic..."

./check-zarouali.sh

echo
echo "================================================"
echo " V4.1 COMPLETED"
echo "================================================"

echo
echo "Reports:"
ls -1 reports

echo
echo "Backup:"
echo "$BACKUP"

echo
echo "Next commands:"
echo
echo "git add ."
echo 'git commit -m "Zarouali Caisse V4.1 images CSV repair"'
echo "git push origin main"

