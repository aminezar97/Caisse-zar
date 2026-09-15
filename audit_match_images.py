import csv
from pathlib import Path

BASE = Path.home() / "Caisse-zar"
CSV = BASE / "www/data/products.csv"
IMG = BASE / "www/images"
REPORT = BASE / "image_match_audit.csv"

with open(CSV, encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f, delimiter=";"))

images = {p.name for p in IMG.iterdir()
          if p.is_file() and p.suffix.lower() in [".jpg",".jpeg",".png",".webp"]}

missing = []
for r in rows:
    image = (r.get("image") or "").strip()
    if image not in images:
        missing.append(r)

with open(REPORT, "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, delimiter=";")
    w.writerow(["id","name","image","status"])
    for r in missing:
        w.writerow([r.get("id",""), r.get("name",""),
                    r.get("image",""), "IMAGE_NOT_FOUND"])

print()
print("================================")
print("ZAROUALI CAISSE IMAGE CHECK")
print("================================")
print("Products :", len(rows))
print("Images   :", len(images))
print("Missing  :", len(missing))
print("Report   :", REPORT)
print()
print("CSV ORIGINAL NOT MODIFIED")
print("IMAGES NOT MODIFIED")
