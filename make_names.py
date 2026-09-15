import csv,re

src="www/data/products.csv"

FR_REMOVE=r"\b(Carrefour|Marjane)\b"
FR_SHORT={
"Concentré de tomate":"Concentré tomate","Nettoyant WC":"Gel WC",
"Liquide vaisselle":"Liquide vaisselle","Adoucissant":"Adoucissant",
"Shampooing bébé":"Shampoing bébé","Eau minérale":"Eau",
"Huile de tournesol":"Huile tournesol","Sucre en morceaux":"Sucre morceaux",
"Thé Vert Aromatisé à la Menthe":"Thé Vert Menthe",
"Anchois à l'huile d'olive extra vierge":"Anchois huile olive",
"Champignons en morceaux":"Champignons morceaux"
}

AR={
"Farine":"دقيق","Riz":"روز","Pâtes":"مكرونة","Spaghetti":"سباغيتي",
"Fusilli":"فوسيلي","Penne":"بيني","Linguine":"لينغويني",
"Couscous":"كسكس","Semoule":"سميدة","Sucre":"سكر","Huile":"زيت",
"Café":"قهوة","Thé":"أتاي","Eau":"ما","minérale":"معدني",
"Shampooing":"شامبو","bébé":"البيبي","Savon":"صابون",
"Lait":"حليب","Fromage":"فرماج","Beurre":"زبدة",
"Nettoyant":"منظف","WC":"المرحاض","Liquide vaisselle":"سائل المواعن",
"Adoucissant":"منعم الملابس","Confiture":"مربى","Miel":"عسل",
"tomate":"طماطم","Concentré":"مركز","Sauce":"صلصة",
"Chocolat":"شكلاط","Biscuits":"بسكويت","Jus":"عصير",
"Anchois":"أنشوبة","Champignons":"فطر","morceaux":"مقطع",
"sel":"الملح","Bouillon":"مرق","cubes":"مكعبات",
"Poulet":"دجاج","Poisson":"حوت","Ail":"ثوم","semoule":"مطحون",
"olive":"الزيتون","huile":"زيت"
}

def fr(n):
    n=re.sub(FR_REMOVE,"",n,flags=re.I)
    for a,b in FR_SHORT.items(): n=n.replace(a,b)
    n=re.sub(r"\s+"," ",n).strip(" -")
    return n[:65]

def ar(n):
    x=n
    for a,b in sorted(AR.items(),key=lambda z:-len(z[0])):
        x=re.sub(r"\b"+re.escape(a)+r"\b",b,x,flags=re.I)
    x=x.replace("g","غ").replace("kg","كلغ").replace("ml","مل").replace("L","ل")
    x=re.sub(r"\s+"," ",x).strip()
    return x[:65]

with open(src,encoding="utf-8-sig",newline="") as f:
    rows=list(csv.DictReader(f,delimiter=";"))

fields=list(rows[0])
for x in ["name_ar","description_fr","description_ar"]:
    if x not in fields: fields.append(x)

for r in rows:
    r["name"]=fr(r["name"])
    r["name_ar"]=ar(r["name"])
    r["description_fr"]=r["name"]
    r["description_ar"]=r["name_ar"]

for lang in ["fr","ar"]:
    with open(f"www/data/products_{lang}.csv","w",encoding="utf-8-sig",newline="") as f:
        w=csv.DictWriter(f,fieldnames=fields,delimiter=";",extrasaction="ignore")
        w.writeheader();w.writerows(rows)

print("DONE:",len(rows))
