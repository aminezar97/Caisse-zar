# ZAROUALI CAISSE — Capacitor Android Offline

Cette version transforme `souk_caisse_android.html` en vraie application Android
avec Capacitor.

## Offline 100 %

L'application ne dépend pas d'un site web pour fonctionner.
Le scanner `html5-qrcode` est copié dans `www/vendor/` pendant la préparation.
Une CSP bloque les connexions réseau depuis la page.

Après installation de l'APK, les fonctions de caisse, produits, ventes,
historique, paramètres et stockage local fonctionnent sans Internet.

## Construction sur Termux

### 1. Installer les outils

    pkg update
    pkg install nodejs-lts openjdk-21 git unzip

Installer/configurer Android SDK + platform-tools + build-tools dans Termux,
puis définir `ANDROID_HOME` vers ton SDK.

### 2. Entrer dans le projet

    cd ZAROUALI_CAISSE_CAPACITOR

### 3. Installer les dépendances

    npm install

Cette étape nécessite Internet une seule fois pour télécharger Capacitor et
html5-qrcode.

### 4. Créer Android et synchroniser

    chmod +x scripts/setup_android.sh
    ./scripts/setup_android.sh

### 5. Générer l'APK de test

    npm run apk:debug

APK obtenu :

    android/app/build/outputs/apk/debug/app-debug.apk

Copie ensuite ce fichier sur un autre téléphone par Bluetooth, USB,
Quick Share, WhatsApp, etc. Le téléphone cible n'a pas besoin d'Internet.

## Important

- L'APK doit être signé pour une distribution définitive.
- Pour partager facilement l'application, utilise l'APK release signé.
- Si Android affiche « package semble ne pas être valide », ne réutilise pas
  l'ancien APK : reconstruis avec ce projet et installe le nouvel APK.
