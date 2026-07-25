package com.gemmea.app

import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gemmea.app/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    try {
                        val file = File(path)
                        // 1. Scan file using Android MediaScannerConnection
                        MediaScannerConnection.scanFile(
                            context,
                            arrayOf(file.absolutePath),
                            arrayOf("application/pdf")
                        ) { _, _ -> }

                        // 2. On Android 10+ (API 29+), also register directly into MediaStore Downloads/Documents
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && file.exists()) {
                            try {
                                val contentValues = ContentValues().apply {
                                    put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
                                    put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOCUMENTS + "/Gemmea")
                                }
                                val uri = contentResolver.insert(MediaStore.Files.getContentUri("external"), contentValues)
                                uri?.let { u ->
                                    contentResolver.openOutputStream(u)?.use { os ->
                                        file.inputStream().use { isStream ->
                                            isStream.copyTo(os)
                                        }
                                    }
                                }
                            } catch (_: Exception) {}
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SCAN_ERROR", e.localizedMessage, null)
                    }
                } else {
                    result.error("BAD_ARGS", "Missing path argument", null)
                }
            } else if (call.method == "openFile") {
                val path = call.argument<String>("path")
                if (path != null) {
                    try {
                        val file = File(path)
                        if (file.exists()) {
                            val uri = FileProvider.getUriForFile(
                                context,
                                "${context.packageName}.fileprovider",
                                file
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, "application/pdf")
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            val chooser = Intent.createChooser(intent, "Ouvrir le PDF avec")
                            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(chooser)
                            result.success(true)
                        } else {
                            result.error("FILE_NOT_FOUND", "File does not exist: $path", null)
                        }
                    } catch (e: Exception) {
                        result.error("OPEN_ERROR", e.localizedMessage, null)
                    }
                } else {
                    result.error("BAD_ARGS", "Missing path argument", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
