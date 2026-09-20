package com.zarouali.caisse;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.util.Base64;

import androidx.activity.result.ActivityResult;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;

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

        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType(mimeType);
        intent.putExtra(Intent.EXTRA_TITLE, fileName);

        startActivityForResult(call, intent, "saveFileResult");
    }

    @ActivityCallback
    private void saveFileResult(PluginCall call, ActivityResult result) {
        if (result.getResultCode() != Activity.RESULT_OK) {
            call.reject("Enregistrement annule");
            return;
        }

        Uri uri = result.getData() != null
                ? result.getData().getData()
                : null;

        if (uri == null) {
            call.reject("Emplacement invalide");
            return;
        }

        try {
            byte[] data = Base64.decode(
                    call.getString("dataBase64", ""),
                    Base64.DEFAULT
            );

            OutputStream out =
                    getContext().getContentResolver().openOutputStream(uri);

            if (out == null) {
                throw new IllegalStateException("Impossible d'ouvrir le fichier");
            }

            out.write(data);
            out.flush();
            out.close();

            JSObject ret = new JSObject();
            ret.put("uri", uri.toString());
            call.resolve(ret);

        } catch (Exception e) {
            call.reject("Echec de l'enregistrement: " + e.getMessage());
        }
    }
}
