/* Zarouali Caisse - Firebase Storage image synchronization
 * Additive/safe layer:
 * - Existing IndexedDB remains the local cache/fallback.
 * - New/local product images are uploaded to Firebase Storage.
 * - Firestore keeps the resulting HTTPS image URL.
 * - Existing products with local/data images are migrated automatically.
 */
(function () {
  "use strict";

  const FIREBASE_VERSION = "12.18.0";
  const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
  const WAIT_MS = 250;
  let installed = false;
  let storageApi = null;
  let originalFsSaveDB = null;
  let migrationStarted = false;

  function waitFor(fn, timeout = 30000) {
    return new Promise((resolve, reject) => {
      const started = Date.now();
      const tick = () => {
        try {
          const value = fn();
          if (value) return resolve(value);
        } catch (_) {}
        if (Date.now() - started > timeout) {
          reject(new Error("Firebase image layer timeout"));
          return;
        }
        setTimeout(tick, WAIT_MS);
      };
      tick();
    });
  }

  function extFrom(name, type) {
    const e = String(name || "")
      .split(".").pop().toLowerCase()
      .replace(/[^a-z0-9]/g, "");
    if (e && e.length <= 5) return e;

    const m = String(type || "").match(
      /image\/(png|jpe?g|webp|gif|avif)/i
    );

    if (!m) return "jpg";
    return m[1].toLowerCase() === "jpeg" ? "jpg" : m[1].toLowerCase();
  }

  function isRemote(v) {
    return /^(https?:|gs:)/i.test(String(v || ""));
  }

  function isData(v) {
    return /^data:image\//i.test(String(v || ""));
  }

  function isLocal(v) {
    const s = String(v || "");
    return !!s && !isRemote(s) && !isData(s) && /(^|\/)images\//i.test(s);
  }

  async function dataUrlToBlob(dataUrl) {
    const response = await fetch(dataUrl);
    return response.blob();
  }

  async function readLocalBlob(imageValue) {
    if (typeof CatalogImages === "undefined") return null;

    const key = CatalogImages.key(imageValue);
    const idb = await CatalogImages.open();

    try {
      return await new Promise((resolve, reject) => {
        const tx = idb.transaction(CatalogImages.STORE, "readonly");
        const req = tx.objectStore(CatalogImages.STORE).get(key);

        req.onsuccess = () => resolve(req.result || null);
        req.onerror = () => reject(req.error);
      });
    } finally {
      idb.close();
    }
  }

  async function uploadBlob(productId, blob, filename) {
    if (!blob) return null;

    if (blob.size > MAX_IMAGE_BYTES) {
      throw new Error("Image trop volumineuse (maximum 5 MB)");
    }

    const ext = extFrom(filename, blob.type);
    const safeId = String(productId || "product")
      .replace(/[^a-zA-Z0-9_-]/g, "_");

    const storageRef = storageApi.ref(
      storageApi.storage,
      `catalog/products/${safeId}/image.${ext}`
    );

    await storageApi.uploadBytes(storageRef, blob, {
      contentType: blob.type || `image/${ext}`
    });

    return storageApi.getDownloadURL(storageRef);
  }

  async function uploadProductImage(product) {
    if (!product || !product.id || !product.image) return null;
    if (isRemote(product.image)) return product.image;

    let blob = null;
    const filename =
      String(product.image).split(/[\\/]/).pop() || "image.jpg";

    if (isData(product.image)) {
      blob = await dataUrlToBlob(product.image);
    } else if (isLocal(product.image)) {
      blob = await readLocalBlob(product.image);
    }

    if (!blob) return null;

    const url = await uploadBlob(product.id, blob, filename);
    if (url) product.image = url;

    return url;
  }

  async function uploadPendingImages(data) {
    if (!data || !Array.isArray(data.products)) {
      return { changed: false, count: 0 };
    }

    let changed = false;
    let count = 0;

    for (const product of data.products) {
      if (!product || !product.image || isRemote(product.image)) continue;

      try {
        const before = product.image;
        const url = await uploadProductImage(product);

        if (url && url !== before) {
          changed = true;
          count++;
        }
      } catch (e) {
        console.warn(
          "[Firebase Storage] image upload failed",
          product.id,
          e
        );
      }
    }

    return { changed, count };
  }

  async function migrateExistingImages() {
    if (migrationStarted) return;
    migrationStarted = true;

    try {
      await waitFor(() =>
        window.fsSaveDB &&
        typeof db !== "undefined" &&
        typeof CatalogImages !== "undefined"
      );

      await CatalogImages.load();

      const result = await uploadPendingImages(db);

      if (result.changed) {
        if (typeof DB_KEY !== "undefined") {
          localStorage.setItem(DB_KEY, JSON.stringify(db));
        }

        if (originalFsSaveDB) {
          await originalFsSaveDB({ ...db });
        }

        if (typeof clearImageCache === "function") {
          clearImageCache();
        }

        if (typeof renderAll === "function") {
          renderAll();
        }

        console.log(
          `[Firebase Storage] migrated ${result.count} product images`
        );
      } else {
        console.log("[Firebase Storage] no local images to migrate");
      }
    } catch (e) {
      console.warn("[Firebase Storage] migration skipped", e);
    }
  }

  async function install() {
    if (installed) return;
    installed = true;

    try {
      const [{ getApp }, storage] = await Promise.all([
        import(
          `https://www.gstatic.com/firebasejs/${FIREBASE_VERSION}/firebase-app.js`
        ),
        import(
          `https://www.gstatic.com/firebasejs/${FIREBASE_VERSION}/firebase-storage.js`
        )
      ]);

      const app = await waitFor(() => {
        try {
          return getApp();
        } catch (_) {
          return null;
        }
      });

      storageApi = {
        storage: storage.getStorage(app),
        ref: storage.ref,
        uploadBytes: storage.uploadBytes,
        getDownloadURL: storage.getDownloadURL
      };

      await waitFor(() => window.fsSaveDB);

      if (window.__ZAR_FIREBASE_STORAGE_LAYER) return;
      window.__ZAR_FIREBASE_STORAGE_LAYER = true;

      originalFsSaveDB = window.fsSaveDB;

      window.fsSaveDB = async function (data) {
        try {
          await uploadPendingImages(data);
        } catch (e) {
          console.warn(
            "[Firebase Storage] pre-save upload failed",
            e
          );
        }

        return originalFsSaveDB(data);
      };

      window.ZaroualiFirebaseImages = {
        uploadProductImage,
        uploadPendingImages,
        migrateExistingImages,
        get ready() {
          return !!storageApi;
        }
      };

      console.log("[Firebase Storage] image sync installed");

      setTimeout(migrateExistingImages, 1200);
    } catch (e) {
      console.warn(
        "[Firebase Storage] layer not installed",
        e
      );
    }
  }

  install();
})();
