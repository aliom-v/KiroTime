package com.kirotime.app

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "kiro_time/timetable_files"
    private val pickJsonRequestCode = 4107
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "exportTimetableJson" -> {
                    val fileName = call.argument<String>("fileName") ?: "KiroTime_课表备份.json"
                    val json = call.argument<String>("json") ?: ""
                    val overwrite = call.argument<Boolean>("overwrite") ?: false
                    try {
                        val displayPath = exportTimetableJson(fileName, json, overwrite)
                        result.success(
                            mapOf(
                                "fileName" to fileName,
                                "displayPath" to displayPath,
                            )
                        )
                    } catch (error: Exception) {
                        result.error("export_failed", error.message, null)
                    }
                }
                "fileExistsInDownloads" -> {
                    val fileName = call.argument<String>("fileName") ?: ""
                    try {
                        result.success(fileExistsInDownloads(fileName))
                    } catch (error: Exception) {
                        result.error("exists_failed", error.message, null)
                    }
                }
                "pickTimetableJson" -> pickTimetableJson(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickJsonRequestCode) {
            return
        }
        val result = pendingPickResult ?: return
        pendingPickResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            result.success(null)
            return
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // Some providers do not offer persistable permissions. The current
            // import only needs immediate read access.
        }
        try {
            val json = contentResolver.openInputStream(uri)?.bufferedReader(Charsets.UTF_8).use { reader ->
                reader?.readText()
            } ?: ""
            result.success(
                mapOf(
                    "fileName" to displayNameFor(uri),
                    "json" to json,
                )
            )
        } catch (error: Exception) {
            result.error("pick_failed", error.message, null)
        }
    }

    private fun pickTimetableJson(result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("picker_active", "A timetable JSON picker is already active.", null)
            return
        }
        pendingPickResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/json", "text/json", "text/plain", "application/octet-stream"),
            )
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        startActivityForResult(intent, pickJsonRequestCode)
    }

    private fun exportTimetableJson(fileName: String, json: String, overwrite: Boolean): String {
        if (fileName.isBlank()) {
            throw IllegalArgumentException("File name is empty.")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return exportWithMediaStore(fileName, json, overwrite)
        }
        @Suppress("DEPRECATION")
        val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val directory = java.io.File(downloads, "KiroTime")
        if (!directory.exists()) {
            directory.mkdirs()
        }
        val file = java.io.File(directory, fileName)
        if (file.exists() && !overwrite) {
            throw IllegalStateException("File already exists.")
        }
        file.writeText(json, Charsets.UTF_8)
        return "Download/KiroTime/$fileName"
    }

    private fun exportWithMediaStore(fileName: String, json: String, overwrite: Boolean): String {
        val existing = findDownloadUri(fileName)
        if (existing != null) {
            if (!overwrite) {
                throw IllegalStateException("File already exists.")
            }
            contentResolver.delete(existing, null, null)
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/json")
            put(MediaStore.MediaColumns.RELATIVE_PATH, "Download/KiroTime")
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = contentResolver.insert(collection, values)
            ?: throw IllegalStateException("Could not create Downloads file.")
        try {
            contentResolver.openOutputStream(uri)?.use { stream ->
                stream.write(json.toByteArray(Charsets.UTF_8))
            } ?: throw IllegalStateException("Could not open Downloads file.")
            val finished = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            contentResolver.update(uri, finished, null, null)
            return "Download/KiroTime/$fileName"
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }

    private fun fileExistsInDownloads(fileName: String): Boolean {
        return findDownloadUri(fileName) != null
    }

    private fun findDownloadUri(fileName: String): Uri? {
        if (fileName.isBlank()) {
            return null
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val projection = arrayOf(MediaStore.MediaColumns._ID)
            val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} = ?"
            val args = arrayOf(fileName, "Download/KiroTime/")
            contentResolver.query(collection, projection, selection, args, null).use { cursor ->
                if (cursor != null && cursor.moveToFirst()) {
                    val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                    return ContentUris.withAppendedId(collection, id)
                }
            }
            return null
        }
        @Suppress("DEPRECATION")
        val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val file = java.io.File(java.io.File(downloads, "KiroTime"), fileName)
        return if (file.exists()) Uri.fromFile(file) else null
    }

    private fun displayNameFor(uri: Uri): String {
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            if (cursor != null && cursor.moveToFirst()) {
                cursor.getString(cursor.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
            } else {
                uri.lastPathSegment ?: "课表备份.json"
            }
        } finally {
            cursor?.close()
        }
    }
}
