package com.example.perception_notes

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val logTag = "PerceptionNotesBackup"
    private val requestCreateDocument = 4107

    private var pendingBytes: ByteArray? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "perception_notes/storage"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveBackupBytes" -> {
                    val fileName = call.argument<String>("fileName")
                    val bytes = call.argument<ByteArray>("bytes")

                    Log.d(logTag, "saveBackupBytes called fileName=$fileName bytes=${bytes?.size}")

                    if (fileName == null || bytes == null) {
                        Log.e(logTag, "Missing backup export arguments.")
                        result.error("invalid_args", "Missing backup export arguments.", null)
                        return@setMethodCallHandler
                    }

                    if (pendingResult != null) {
                        Log.e(logTag, "Another export is already in progress.")
                        result.error("busy", "Another export is already in progress.", null)
                        return@setMethodCallHandler
                    }

                    pendingBytes = bytes
                    pendingResult = result

                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/json"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }

                    try {
                        startActivityForResult(intent, requestCreateDocument)
                    } catch (exception: Exception) {
                        Log.e(logTag, "Failed to launch create-document intent: ${exception.message}", exception)
                        pendingBytes = null
                        pendingResult = null
                        result.error("launch_failed", exception.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != requestCreateDocument) {
            return
        }

        val result = pendingResult
        val bytes = pendingBytes

        if (result == null || bytes == null) {
            Log.e(logTag, "onActivityResult without pending export state.")
            pendingResult = null
            pendingBytes = null
            return
        }

        try {
            val uri: Uri? = data?.data
            if (resultCode != RESULT_OK || uri == null) {
                Log.d(logTag, "Create document cancelled or returned no URI.")
                result.success(null)
            } else {
                Log.d(logTag, "Create document returned uri=$uri bytes=${bytes.size}")
                contentResolver.openOutputStream(uri)?.use { stream ->
                    stream.write(bytes)
                    stream.flush()
                    Log.d(logTag, "Backup bytes written successfully.")
                } ?: run {
                    Log.e(logTag, "Could not open output stream for uri=$uri")
                    result.error("write_failed", "Could not open backup output stream.", null)
                    pendingResult = null
                    pendingBytes = null
                    return
                }
                result.success(uri.toString())
            }
        } catch (exception: Exception) {
            Log.e(logTag, "Export failed with exception: ${exception.message}", exception)
            result.error("write_failed", exception.message, null)
        }

        pendingResult = null
        pendingBytes = null
    }
}
