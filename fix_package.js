const fs = require('fs');
const pkgPath = './package.json';
if (fs.existsSync(pkgPath)) {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    pkg.main = "main.js";
    pkg.build = {
        "appId": "com.zarouali.caisse",
        "productName": "Zarouali Caisse",
        "directories": { "output": "dist" },
        "win": { "target": "nsis" },
        "files": ["main.js", "www/**/*"]
    };
    fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
    console.log("✔️ تم تحديث package.json بنجاح!");
}
