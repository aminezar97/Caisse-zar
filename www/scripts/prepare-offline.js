const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const source = path.join(root, 'node_modules', 'html5-qrcode', 'html5-qrcode.min.js');
const destDir = path.join(root, 'www', 'vendor');
const dest = path.join(destDir, 'html5-qrcode.min.js');

if (!fs.existsSync(source)) {
  console.error('html5-qrcode is not installed. Run: npm install');
  process.exit(1);
}
fs.mkdirSync(destDir, { recursive: true });
fs.copyFileSync(source, dest);
console.log('Offline scanner bundled:', dest);
