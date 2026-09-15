from pathlib import Path

p=Path("www/index.html")
s=p.read_text()

start=s.index('  try{\n    const r=await fetch("./data/products_"+currentLanguage')
end=s.index('\n  }catch(e){}',start)+len('\n  }catch(e){}')

new='''  // ===== ZAROUALI CATALOG : SQLite/ZIP =====
  // No products are bundled in the GitHub project.
  // The administrator imports Zarouali_Catalog_FINAL.zip from the app.
  try{
    await loadImportedCatalog();
  }catch(e){
    console.warn("Catalog not imported yet:",e);
  }'''

s=s[:start]+new+s[end:]

p.write_text(s)
print("✅ CSV loader replaced by SQLite catalog loader")
