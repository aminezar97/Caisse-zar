#!/data/data/com.termux/files/usr/bin/bash

set -e

PROJECT="$HOME/Caisse-zar"
WWW="$PROJECT/www"
LOGO="$PROJECT/logo.png"

echo "=========================================="
echo "   ZAROUALI POS - Logo Installer"
echo "=========================================="

# ------------------------------------------
# 1. Vérifications
# ------------------------------------------

if [ ! -d "$PROJECT" ]; then
    echo "❌ Project not found: $PROJECT"
    exit 1
fi

if [ ! -f "$LOGO" ]; then
    echo "❌ Logo not found:"
    echo "$LOGO"
    echo
    echo "Place the new logo here first:"
    echo "~/Caisse-zar/logo.png"
    exit 1
fi

if [ ! -d "$WWW" ]; then
    echo "❌ www directory not found"
    exit 1
fi

echo "✅ Project found"
echo "✅ Logo found"

# ------------------------------------------
# 2. Backup
# ------------------------------------------

BACKUP="$PROJECT/.logo_backup_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP"

echo "📦 Creating backup..."

for f in \
    "$WWW/icon.png" \
    "$WWW/favicon.png" \
    "$WWW/favicon.ico" \
    "$WWW/apple-touch-icon.png" \
    "$WWW/manifest.webmanifest" \
    "$WWW/manifest.json"
do
    if [ -f "$f" ]; then
        cp "$f" "$BACKUP/"
    fi
done

echo "✅ Backup: $BACKUP"

# ------------------------------------------
# 3. Web logo
# ------------------------------------------

echo "🌐 Installing web logo..."

mkdir -p "$WWW/assets"

cp "$LOGO" "$WWW/assets/logo.png"
cp "$LOGO" "$WWW/icon.png"

# favicon
cp "$LOGO" "$WWW/favicon.png"

# Apple / PWA icon
cp "$LOGO" "$WWW/apple-touch-icon.png"

echo "✅ Web logo installed"

# ------------------------------------------
# 4. Detect image tools
# ------------------------------------------

if command -v magick >/dev/null 2>&1; then
    IMG="magick"
elif command -v convert >/dev/null 2>&1; then
    IMG="convert"
else
    IMG=""
fi

# ------------------------------------------
# 5. Generate favicon sizes
# ------------------------------------------

if [ -n "$IMG" ]; then

    echo "🖼️ Generating favicon sizes..."

    mkdir -p "$WWW/icons"

    "$IMG" "$LOGO" -resize 192x192 "$WWW/icons/icon-192.png"
    "$IMG" "$LOGO" -resize 512x512 "$WWW/icons/icon-512.png"
    "$IMG" "$LOGO" -resize 180x180 "$WWW/icons/apple-touch-icon.png"
    "$IMG" "$LOGO" -resize 32x32 "$WWW/icons/favicon-32.png"
    "$IMG" "$LOGO" -resize 16x16 "$WWW/icons/favicon-16.png"

    cp "$WWW/icons/icon-192.png" "$WWW/icon-192.png"
    cp "$WWW/icons/icon-512.png" "$WWW/icon-512.png"

    echo "✅ Icons generated"

else

    echo "⚠️ ImageMagick not installed"
    echo "Skipping automatic resizing."
    echo "The original logo was still installed."

fi

# ------------------------------------------
# 6. Update manifest.webmanifest
# ------------------------------------------

MANIFEST="$WWW/manifest.webmanifest"

if [ -f "$MANIFEST" ]; then

    echo "📱 Updating manifest.webmanifest..."

    python3 - "$MANIFEST" <<'PY'
import json
import sys

path = sys.argv[1]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

icons = [
    {
        "src": "./icons/icon-192.png",
        "sizes": "192x192",
        "type": "image/png",
        "purpose": "any maskable"
    },
    {
        "src": "./icons/icon-512.png",
        "sizes": "512x512",
        "type": "image/png",
        "purpose": "any maskable"
    }
]

data["icons"] = icons

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

PY

    echo "✅ manifest.webmanifest updated"

fi

# ------------------------------------------
# 7. Update manifest.json if exists
# ------------------------------------------

MANIFEST2="$WWW/manifest.json"

if [ -f "$MANIFEST2" ]; then

    echo "📱 Updating manifest.json..."

    python3 - "$MANIFEST2" <<'PY'
import json
import sys

path = sys.argv[1]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

data["icons"] = [
    {
        "src": "./icons/icon-192.png",
        "sizes": "192x192",
        "type": "image/png",
        "purpose": "any maskable"
    },
    {
        "src": "./icons/icon-512.png",
        "sizes": "512x512",
        "type": "image/png",
        "purpose": "any maskable"
    }
]

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

PY

    echo "✅ manifest.json updated"

fi

# ------------------------------------------
# 8. Update HTML references
# ------------------------------------------

echo "🔗 Updating HTML logo references..."

find "$WWW" -type f \( -name "*.html" -o -name "*.htm" \) -print0 |
while IFS= read -r -d '' file
do

    sed -i \
        -e 's#src=["'\'']\./icon\.png["'\'']#src="./assets/logo.png"#g' \
        -e 's#src=["'\'']icon\.png["'\'']#src="./assets/logo.png"#g' \
        -e 's#href=["'\'']\./icon\.png["'\'']#href="./assets/logo.png"#g' \
        -e 's#href=["'\'']icon\.png["'\'']#href="./assets/logo.png"#g' \
        "$file"

done

echo "✅ HTML references updated"

# ------------------------------------------
# 9. Add favicon to HTML if missing
# ------------------------------------------

INDEX="$WWW/index.html"

if [ -f "$INDEX" ]; then

    if ! grep -qi 'favicon.png' "$INDEX"; then

        python3 - "$INDEX" <<'PY'
import sys

path = sys.argv[1]

with open(path, "r", encoding="utf-8") as f:
    html = f.read()

tag = '''
<link rel="icon" type="image/png" sizes="192x192" href="./icons/icon-192.png">
<link rel="apple-touch-icon" href="./icons/apple-touch-icon.png">
'''

if "</head>" in html:
    html = html.replace("</head>", tag + "\n</head>", 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(html)

PY

        echo "✅ Favicon added to index.html"

    else
        echo "ℹ️ Favicon already exists"
    fi

fi

# ------------------------------------------
# 10. Capacitor assets
# ------------------------------------------

echo "📦 Preparing Capacitor assets..."

mkdir -p "$PROJECT/assets"

cp "$LOGO" "$PROJECT/assets/logo.png"

echo "✅ assets/logo.png installed"

# ------------------------------------------
# 11. Capacitor asset generation
# ------------------------------------------

if [ -f "$PROJECT/package.json" ]; then

    if grep -q "@capacitor/assets" "$PROJECT/package.json"; then

        echo "⚙️ @capacitor/assets detected"

        (
            cd "$PROJECT"

            npx @capacitor/assets generate \
                --iconBackgroundColor "#ffffff" \
                --iconBackgroundColorDark "#ffffff" \
                --splashBackgroundColor "#ffffff" \
                --splashBackgroundColorDark "#ffffff"
        ) || {
            echo "⚠️ Capacitor asset generation failed"
            echo "Web assets were still installed successfully."
        }

    else

        echo "ℹ️ @capacitor/assets not installed"
        echo "Native icon generation skipped."

    fi

fi

# ------------------------------------------
# 12. Android detection
# ------------------------------------------

if [ -d "$PROJECT/android" ]; then

    echo "🤖 Android project detected"

    echo "ℹ️ Capacitor native assets should be regenerated"
    echo "   using @capacitor/assets."

fi

# ------------------------------------------
# 13. Search old logo references
# ------------------------------------------

echo
echo "🔍 Checking remaining logo references..."

grep -RniE \
    "icon\.png|favicon|apple-touch-icon|logo\.png" \
    "$WWW" \
    --include="*.html" \
    --include="*.js" \
    --include="*.css" \
    --include="*.json" \
    2>/dev/null |
head -50 || true

# ------------------------------------------
# 14. Git status
# ------------------------------------------

echo
echo "=========================================="
echo "✅ LOGO INSTALLATION COMPLETED"
echo "=========================================="

echo
echo "Logo:"
echo "  $LOGO"

echo
echo "Web:"
echo "  $WWW/assets/logo.png"
echo "  $WWW/icon.png"
echo "  $WWW/favicon.png"

echo
echo "PWA:"
echo "  $WWW/icons/icon-192.png"
echo "  $WWW/icons/icon-512.png"

echo
echo "Capacitor:"
echo "  $PROJECT/assets/logo.png"

echo
echo "Backup:"
echo "  $BACKUP"

echo
echo "Git changes:"
git -C "$PROJECT" status --short

echo
echo "Next:"
echo "  git add ."
echo "  git commit -m 'Update Zarouali supermarket logo'"
echo "  git push origin main"

echo
echo "🚀 Done."
