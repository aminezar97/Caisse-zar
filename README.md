# 🛒 Zarouali Caisse — Zarouali Supermarché

Application de caisse (POS) hors-ligne, avec le vrai logo et catalogue **Zarouali Supermarché** (684 produits + images) déjà intégrés.

Depuis le même code source (`www/index.html`), 3 versions sont générées automatiquement via **GitHub Actions** :

| Version | Outil | Résultat |
|---|---|---|
| 🌐 Site Web / PWA | GitHub Pages | Lien web installable depuis le navigateur |
| 📱 Application Android | Capacitor | `.apk` (installable direct) + `.aab` (Play Store) |
| 🖥️ Application Windows | Electron Builder | `Setup.exe` + version portable |

## Nouveautés de cette mise à jour
- **Logo réel** intégré partout : icône app, écran de démarrage, PWA, en-tête de l'application (remplace l'ancien badge "SC").
- **Catalogue complet importé** : 684 produits + 684 images dans `www/images/`, prêt à importer via *Réglages → Données → Importer CSV*.
- **Nouvelle fonctionnalité "Importer CSV"** ajoutée à l'application (elle n'existait pas avant) : importe en masse `id;name;category;barcode;price;stock;minStock;image`, crée automatiquement les catégories manquantes et ignore les doublons (code-barres déjà présent).
- **Workflow CI corrigé** : les actions GitHub étaient sur d'anciennes versions Node 20 (dépréciées le 16/09/2026) → mises à jour vers les versions Node 24 actuelles.
- **Bug de build Android corrigé** : le job copiait `app-release.apk`, qui n'existe pas pour un build non signé (le fichier réel est `app-release-unsigned.apk`) → copie désormais tolérante quel que soit le nom exact.
- **Génération automatique des icônes Android** à partir du vrai logo (`resources/icon.png` + `@capacitor/assets`).
- **Versions Capacitor fixées** (`^8.5.0` pour core/cli/android au lieu de `latest` non synchronisé, source d'incompatibilités).
- Nettoyage : suppression des fichiers dupliqués (`manifest.json` orphelin, icônes SVG génériques, `electron/main.js` en double).

## ⚠️ Le prix de la plupart des produits est vide dans le CSV
Sur 684 produits, seuls 9 ont un prix renseigné dans le fichier fourni. Après import, allez dans **Produits** et complétez les prix manuellement (ou éditez `data/zarouali_caisse_import.csv` avant de le réimporter).

## Structure du projet
```
Caisse-zar/
├── .github/workflows/build.yml   # Web + Android APK/AAB + Windows Setup.exe
├── www/
│   ├── index.html                # Code de l'application (source unique)
│   ├── manifest.webmanifest      # PWA (icônes = vrai logo)
│   ├── sw.js                     # Service Worker (hors-ligne)
│   ├── icons/                    # icon-192.png / icon-512.png (logo réel)
│   ├── images/                   # 684 images produits
│   └── favicon.png
├── data/zarouali_caisse_import.csv  # Catalogue de départ (684 produits)
├── electron/main.cjs              # Fenêtre desktop (Windows/Linux/Mac)
├── resources/icon.png, splash.png # Sources icône & écran de démarrage
├── capacitor.config.json
├── package.json
└── .gitignore
```

## Comment fonctionne l'automatisation (Workflow)
À chaque `push` sur `main` (ou lancement manuel depuis l'onglet Actions) :

1. **web** — publie `www/` sur GitHub Pages.
2. **android** — installe Node/Java, crée le projet Capacitor Android, régénère les icônes depuis le vrai logo, corrige le `junitVersion` si besoin, puis construit :
   - `Zarouali-Caisse.apk` (debug, installable directement)
   - `Zarouali-Caisse-release-unsigned.apk`
   - `Zarouali-Caisse.aab` (pour Play Store, à signer)
3. **windows** — construit `Zarouali-Caisse-*.exe` (installeur NSIS + version portable) via `electron-builder`.

### Télécharger les résultats
Onglet **Actions** → dernier run réussi (✅) → section **Artifacts** :
- `Zarouali-Caisse-Android` → dézipper, installer l'APK sur le téléphone.
- `Zarouali-Caisse-Windows` → lancer le `.exe`.
- Le site web se déploie automatiquement sur `https://<utilisateur>.github.io/Caisse-zar/`.

### Activer GitHub Pages (une seule fois)
Settings → Pages → Build and deployment → Source : **GitHub Actions**.

## Importer le catalogue de produits
1. Ouvrir l'app → **Réglages** → **Données** → **📥 Importer CSV (catalogue)**.
2. Sélectionner `data/zarouali_caisse_import.csv`.
3. Les 684 produits sont ajoutés avec leurs images (déjà présentes dans `www/images/`), les catégories sont créées automatiquement.
4. Compléter les prix manquants dans l'onglet **Produits**.

## Développement local
```bash
npm install

# Android (nécessite Android Studio, ou laissez GitHub Actions le faire)
npm run cap:add
npm run assets:generate
npm run cap:sync

# Application desktop (test rapide)
npm run electron

# Construire le Setup.exe localement (Windows uniquement)
npm run electron:build
```

## Notes
- Toutes les données (produits, ventes, réglages) sont stockées localement (`localStorage`) — aucun serveur externe.
- Utilisez « Exporter JSON » régulièrement pour sauvegarder.
- L'APK release est **non signé** — valable pour test/installation directe. Pour Google Play, il faut le signer avec un keystore.
