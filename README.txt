Zarouali Caisse - IMAGE PATH FIX

IMPORTANT:
The image column now contains relative paths such as images/187.jpg.
Keep the CSV file and the images folder at the same application root level.

Expected structure:
  zarouali_caisse_import.csv
  images/
    1.jpg
    2.jpg
    ...

For HTML/JS, use the CSV image value directly:
  <img src="${product.image}">

Do NOT add another "images/" prefix if the CSV value already starts with images/.

This package contains the same 684 products and 684 images from the verified package, with corrected image paths for local/offline Android WebView/HTML use.
