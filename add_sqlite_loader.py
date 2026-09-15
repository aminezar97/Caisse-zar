from pathlib import Path

p=Path("www/index.html")
s=p.read_text()

code=r'''
async function loadImportedCatalog(file){
  if(!file) return false;
  if(typeof JSZip==="undefined") throw new Error("JSZip not loaded");
  if(typeof initSqlJs==="undefined") throw new Error("sql.js not loaded");

  const zip=await JSZip.loadAsync(file);
  const dbFile=zip.file("catalog.db");
  if(!dbFile) throw new Error("catalog.db introuvable dans le ZIP");

  const bytes=await dbFile.async("uint8array");
  const SQL=await initSqlJs({
    locateFile:()=> "./vendor/sql-wasm.wasm"
  });
  const catalogDB=new SQL.Database(bytes);

  const result=catalogDB.exec(
    "SELECT id,name,category,barcode,price,purchasePrice,stock,minStock,image FROM products"
  );

  if(!result.length) throw new Error("Table products vide ou absente");

  const cols=result[0].columns;
  const rows=result[0].values;

  db.products=rows.map(r=>{
    const p={};
    cols.forEach((c,i)=>p[c]=r[i]??"");
    p.price=Number(p.price)||0;
    p.purchasePrice=Number(p.purchasePrice)||p.price*0.65;
    p.stock=Number(p.stock)||0;
    p.minStock=Number(p.minStock)||5;
    return p;
  });

  saveDB();
  renderAll();
  updateStorePreview();

  localStorage.setItem("zarouali_catalog_imported","1");
  localStorage.setItem("zarouali_catalog_count",String(db.products.length));

  return true;
}
'''

marker="async function init(){"
if "async function loadImportedCatalog(" not in s:
    s=s.replace(marker,code+"\n"+marker,1)
    p.write_text(s)
    print("OK: SQLite loader added")
else:
    print("Already exists")
