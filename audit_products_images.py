from pathlib import Path
import csv
import re
from collections import Counter

CSV_FILE = Path("www/data/products.csv")
IMAGE_DIR = Path("www/images")
REPORT = Path("image_product_audit.csv")

print("=" * 60)
print(" ZAROUALI CAISSE - PRODUCT / IMAGE AUDIT")
print("=" * 60)

if not CSV_FILE.exists():
    raise SystemExit("❌ products.csv not found")

if not IMAGE_DIR.exists():
    raise SystemExit("❌ www/images not found")

# ---------------------------------------------------------
# READ CSV
# ---------------------------------------------------------

text = CSV_FILE.read_text(encoding="utf-8-sig")

# Remove BOM and normalize line endings
text = text.replace("\r\n", "\n").replace("\r", "\n")

rows = list(csv.reader(text.splitlines(), delimiter=";"))

if not rows:
    raise SystemExit("❌ Empty CSV")

header = rows[0]

print("CSV columns:", len(header))
print("Header:", header)

expected = [
    "id",
    "name",
    "category",
    "barcode",
    "price",
    "purchasePrice",
    "stock",
    "minStock",
    "image",
    "expirationDate"
]

# ---------------------------------------------------------
# NORMALIZE HEADER
# ---------------------------------------------------------

header_clean = [x.strip() for x in header]

if header_clean != expected:
    print()
    print("⚠️ Header differs from expected:")
    print("Expected:", expected)
    print("Actual:  ", header_clean)

# ---------------------------------------------------------
# IMAGE INDEX
# ---------------------------------------------------------

image_files = {}

for p in IMAGE_DIR.iterdir():
    if p.is_file():
        image_files[p.name.lower()] = p.name

print()
print("Images found:", len(image_files))

# ---------------------------------------------------------
# ANALYZE PRODUCTS
# ---------------------------------------------------------

report = []

ids = []
names = []
barcodes = []
images = []

missing_images = []
wrong_image_names = []
invalid_rows = []
duplicate_ids = []
duplicate_names = []
duplicate_barcodes = []
duplicate_images = []

for line_number, row in enumerate(rows[1:], start=2):

    # Ignore completely empty lines
    if not any(x.strip() for x in row):
        continue

    if len(row) != 10:
        invalid_rows.append((line_number, len(row), row))
        continue

    (
        pid,
        name,
        category,
        barcode,
        price,
        purchase_price,
        stock,
        min_stock,
        image,
        expiration
    ) = [x.strip() for x in row]

    ids.append(pid)
    names.append(name.lower())
    if barcode:
        barcodes.append(barcode)

    images.append(image.lower())

    # Expected image = ID.jpg
    expected_image = f"{pid}.jpg"

    if not image:
        status = "MISSING_IMAGE_FIELD"

    elif image.lower() not in image_files:
        status = "IMAGE_FILE_NOT_FOUND"
        missing_images.append((pid, name, image))

    elif image.lower() != expected_image.lower():
        status = "IMAGE_NAME_NOT_ID"
        wrong_image_names.append(
            (pid, name, image, expected_image)
        )

    else:
        status = "OK"

    report.append({
        "id": pid,
        "name": name,
        "category": category,
        "barcode": barcode,
        "price": price,
        "purchasePrice": purchase_price,
        "stock": stock,
        "minStock": min_stock,
        "image": image,
        "expirationDate": expiration,
        "expectedImage": expected_image,
        "status": status
    })

# ---------------------------------------------------------
# DUPLICATES
# ---------------------------------------------------------

def duplicates(values):
    c = Counter(values)
    return sorted([x for x, n in c.items() if n > 1])

duplicate_ids = duplicates(ids)
duplicate_names = duplicates(names)
duplicate_barcodes = duplicates(barcodes)
duplicate_images = duplicates(images)

# ---------------------------------------------------------
# SAVE REPORT
# ---------------------------------------------------------

report_header = [
    "id",
    "name",
    "category",
    "barcode",
    "price",
    "purchasePrice",
    "stock",
    "minStock",
    "image",
    "expirationDate",
    "expectedImage",
    "status"
]

with REPORT.open("w", encoding="utf-8-sig", newline="") as f:
    writer = csv.DictWriter(
        f,
        fieldnames=report_header,
        delimiter=";"
    )

    writer.writeheader()
    writer.writerows(report)

# ---------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------

print()
print("=" * 60)
print(" RESULTS")
print("=" * 60)

print("Products analyzed :", len(report))
print("Images found      :", len(image_files))
print("Missing images    :", len(missing_images))
print("Wrong image name  :", len(wrong_image_names))
print("Invalid CSV rows  :", len(invalid_rows))
print("Duplicate IDs     :", len(duplicate_ids))
print("Duplicate names   :", len(duplicate_names))
print("Duplicate barcode :", len(duplicate_barcodes))
print("Duplicate images  :", len(duplicate_images))

print()
print("Report:", REPORT)

# ---------------------------------------------------------
# DETAILS
# ---------------------------------------------------------

if missing_images:
    print()
    print("===== MISSING IMAGES =====")
    for x in missing_images[:100]:
        print(x)

if wrong_image_names:
    print()
    print("===== IMAGE NAME ≠ ID =====")
    for x in wrong_image_names[:100]:
        print(x)

if invalid_rows:
    print()
    print("===== INVALID CSV ROWS =====")
    for x in invalid_rows[:50]:
        print("Line:", x[0], "Columns:", x[1])

if duplicate_ids:
    print()
    print("===== DUPLICATE IDs =====")
    print(duplicate_ids)

if duplicate_names:
    print()
    print("===== DUPLICATE NAMES =====")
    for name in duplicate_names:
        print(name)

if duplicate_barcodes:
    print()
    print("===== DUPLICATE BARCODES =====")
    print(duplicate_barcodes)

print()
print("=" * 60)
print("AUDIT FINISHED")
print("=" * 60)
