package com.example.flash_stream

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "flash_stream/file_export"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            if (call.method != "exportFile") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            val fileName = call.argument<String>("fileName")
            if (path.isNullOrBlank() || fileName.isNullOrBlank()) {
                result.error("bad_args", "Missing export path or file name", null)
                return@setMethodCallHandler
            }

            exportFile(path, fileName, result)
        }
    }

    private fun exportFile(path: String, fileName: String, result: MethodChannel.Result) {
        val mainHandler = Handler(Looper.getMainLooper())
        thread(name = "flash-stream-export") {
            try {
                val source = File(path)
                if (!source.exists()) {
                    throw IllegalArgumentException("Source file does not exist: $path")
                }

                val exportedPath = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    exportWithMediaStore(source, fileName)
                } else {
                    exportToPublicDownloads(source, fileName)
                }

                mainHandler.post { result.success(exportedPath) }
            } catch (error: Throwable) {
                mainHandler.post {
                    result.error("export_failed", error.message, null)
                }
            }
        }
    }

    private fun exportWithMediaStore(source: File, fileName: String): String {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "application/octet-stream")
            put(MediaStore.Downloads.RELATIVE_PATH, "Download/FlashStream")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Unable to create Downloads entry")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                source.inputStream().use { input ->
                    input.copyTo(output, DEFAULT_BUFFER_SIZE)
                }
            } ?: throw IllegalStateException("Unable to open export stream")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        } catch (error: Throwable) {
            resolver.delete(uri, null, null)
            throw error
        }
    }

    private fun exportToPublicDownloads(source: File, fileName: String): String {
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            "FlashStream"
        )
        if (!dir.exists() && !dir.mkdirs()) {
            throw IllegalStateException("Unable to create export directory")
        }

        val target = File(dir, fileName)
        source.inputStream().use { input ->
            target.outputStream().use { output ->
                input.copyTo(output, DEFAULT_BUFFER_SIZE)
            }
        }
        return target.absolutePath
    }

}
