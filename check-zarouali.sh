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
