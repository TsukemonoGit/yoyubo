package com.example.yoyuboo

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val channelName = "com.example.yoyuboo/file"
    private val prefKey = "file_uri"
    private val backupFileName = "yoyuboo_backup.json"
    private val requestOpen = 1
    private val requestCreate = 2

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "openFile" -> openFile(result)
                        "createFile" -> createFile(result)
                        "hasStoredUri" -> result.success(loadUri() != null)
                        "readFile" -> readFile(result)
                        "writeFile" -> {
                            val content = call.argument<String>("content")
                            if (content != null) writeFile(content, result)
                            else result.error("INVALID_ARG", "content is null", null)
                        }
                        "readBackup" -> readBackup(result)
                        else -> result.notImplemented()
                    }
                }
    }

    // --- 既存ファイルを開く（ACTION_OPEN_DOCUMENT）---
    private fun openFile(result: MethodChannel.Result) {
        pendingResult = result
        val intent =
                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                }
        @Suppress("DEPRECATION") startActivityForResult(intent, requestOpen)
    }

    // --- 新規ファイルを作成（ACTION_CREATE_DOCUMENT）---
    private fun createFile(result: MethodChannel.Result) {
        pendingResult = result
        val intent =
                Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "*/*"
                    putExtra(Intent.EXTRA_TITLE, "yoyuboo.json")
                }
        @Suppress("DEPRECATION") startActivityForResult(intent, requestCreate)
    }

    @Deprecated("Required for SAF with FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION") super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != requestOpen && requestCode != requestCreate) return

        val pending = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pending.success(false)
            return
        }

        val uri = data.data!!
        contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        )
        saveUri(uri)
        pending.success(true)
    }

    // --- ファイル読み込み ---
    private fun readFile(result: MethodChannel.Result) {
        val uri = loadUri()
        if (uri == null) {
            result.error("NO_URI", "No file URI stored", null)
            return
        }
        try {
            val content =
                    contentResolver.openInputStream(uri)?.use { it.bufferedReader().readText() }
            // ファイル選択時にJSONに絞れないため、読み込み後にバリデーション
            if (content != null) {
                val trimmed = content.trim()
                if (trimmed.isEmpty()) {
                    result.success(null)
                    return
                }
                if (!trimmed.startsWith("{") && !trimmed.startsWith("[")) {
                    result.error("INVALID_JSON", "Selected file is not a JSON file", null)
                    return
                }
            }
            result.success(content)
        } catch (e: Exception) {
            result.error("READ_ERROR", e.message, null)
        }
    }

    // --- ファイル書き込み + バックアップ ---
    private fun writeFile(content: String, result: MethodChannel.Result) {
        val uri = loadUri()
        if (uri == null) {
            result.error("NO_URI", "No file URI stored", null)
            return
        }
        try {
            android.util.Log.d(
                    "MainActivity",
                    "writeFile: uri=$uri, contentLength=${content.length}"
            )
            contentResolver.openFileDescriptor(uri, "wt")?.use { pfd ->
                java.io.FileOutputStream(pfd.fileDescriptor).use { fos ->
                    fos.write(content.toByteArray())
                    fos.flush()
                }
            }
            android.util.Log.d("MainActivity", "writeFile: success")
            saveBackup(content)
            result.success(null)
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "writeFile: error=${e.message}", e)
            result.error("WRITE_ERROR", e.message, null)
        }
    }

    // --- バックアップ読み込み ---
    private fun readBackup(result: MethodChannel.Result) {
        val backupFile = File(filesDir, backupFileName)
        if (!backupFile.exists()) {
            result.error("NO_BACKUP", "No backup file found", null)
            return
        }
        try {
            result.success(backupFile.readText())
        } catch (e: Exception) {
            result.error("READ_ERROR", e.message, null)
        }
    }

    // --- バックアップ保存（3世代ローテーション） ---
    private fun saveBackup(content: String) {
        try {
            for (i in 2 downTo 1) {
                val old = File(filesDir, "yoyuboo_backup_$i.json")
                val new = File(filesDir, "yoyuboo_backup_${i + 1}.json")
                if (old.exists()) old.renameTo(new)
            }
            val current = File(filesDir, backupFileName)
            if (current.exists()) {
                current.copyTo(File(filesDir, "yoyuboo_backup_1.json"), overwrite = true)
            }
            current.writeText(content)
        } catch (_: Exception) {
            // バックアップ失敗はサイレントに無視
        }
    }

    // --- URI の永続化 ---
    private fun saveUri(uri: Uri) {
        getSharedPreferences("yoyuboo_prefs", Context.MODE_PRIVATE)
                .edit()
                .putString(prefKey, uri.toString())
                .apply()
    }

    private fun loadUri(): Uri? {
        val uriString =
                getSharedPreferences("yoyuboo_prefs", Context.MODE_PRIVATE).getString(prefKey, null)
        return uriString?.let { Uri.parse(it) }
    }
}
