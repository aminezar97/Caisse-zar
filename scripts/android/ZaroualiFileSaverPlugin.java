package com.zarouali.caisse;

import android.content.ContentValues;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;

@CapacitorPlugin(name = "ZaroualiFileSaver")
public class ZaroualiFileSaverPlugin extends Plugin {

    @PluginMethod
    public void saveFile(PluginCall call) {
        String fileName = call.getString("fileName", "Zarouali_Caisse_export");
        String mimeType = call.getString("mimeType", "application/octet-stream");
        String dataBase64 = call.getString("dataBase64", "");

        if (dataBase64.isEmpty()) {
            call.reject("Donnees du fichier vides");
            return;
        }

        try {
            byte[] data = Base64.decode(dataBase64, Base64.DEFAULT);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveToDownloads(call, fileName, mimeType, data);
            } else {
                saveToDownloadsLegacy(call, fileName, data);
            }

        } catch (Exception e) {
            call.reject("Echec de l'enregistrement: " + e.getMessage());
        }
    }

    private void saveToDownloads(
            PluginCall call,
            String fileName,
            String mimeType,
            byte[] data
    ) throws Exception {

        ContentValues values = new ContentValues();
        values.put(MediaStore.Downloads.DISPLAY_NAME, fileName);
        values.put(MediaStore.Downloads.MIME_TYPE, mimeType);
        values.put(
            MediaStore.Downloads.RELATIVE_PATH,
            Environment.DIRECTORY_DOWNLOADS + "/Zarouali-Caisse"
        );
        values.put(MediaStore.Downloads.IS_PENDING, 1);

        Uri uri = getContext()
                .getContentResolver()
                .insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);

        if (uri == null) {
            throw new IllegalStateException(
                "Impossible de creer le fichier dans Download"
            );
        }

        try {
            OutputStream out =
                getContext().getContentResolver().openOutputStream(uri);

            if (out == null) {
                throw new IllegalStateException(
                    "Impossible d'ouvrir le fichier"
                );
            }

            out.write(data);
            out.flush();
            out.close();

            ContentValues done = new ContentValues();
            done.put(MediaStore.Downloads.IS_PENDING, 0);

            getContext().getContentResolver().update(
                uri,
                done,
                null,
                null
            );

            JSObject ret = new JSObject();
            ret.put("uri", uri.toString());
            ret.put(
                "path",
                "Download/Zarouali-Caisse/" + fileName
            );
            ret.put("fileName", fileName);

            call.resolve(ret);

        } catch (Exception e) {
            getContext().getContentResolver()
                .delete(uri, null, null);
            throw e;
        }
    }

    @SuppressWarnings("deprecation")
    private void saveToDownloadsLegacy(
            PluginCall call,
            String fileName,
            byte[] data
    ) throws Exception {

        File downloads =
            Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            );

        File folder = new File(
            downloads,
            "Zarouali-Caisse"
        );

        if (!folder.exists() && !folder.mkdirs()) {
            throw new IllegalStateException(
                "Impossible de creer Download/Zarouali-Caisse"
            );
        }

        File target = new File(folder, fileName);

        try (FileOutputStream out =
                new FileOutputStream(target)) {
            out.write(data);
        }

        JSObject ret = new JSObject();
        ret.put(
            "uri",
            Uri.fromFile(target).toString()
        );
        ret.put(
            "path",
            "Download/Zarouali-Caisse/" + fileName
        );
        ret.put("fileName", fileName);

        call.resolve(ret);
    }
}
