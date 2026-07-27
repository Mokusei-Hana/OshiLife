package com.example.oshilife

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/**
 * Kotlin share shim (plan §7.2) — the whole native surface of the import
 * flow. Extracts `ACTION_SEND` payloads (`EXTRA_TEXT` plus an optional
 * `EXTRA_STREAM` image, capped like the iOS extension) and hands them to
 * Dart over the `oshilife/share` MethodChannel. A share that launched the
 * app is buffered until the Dart side asks for it with
 * `consumeInitialShare`; shares into the running app are pushed as
 * `onShareReceived` events.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var bufferedShare: Map<String, Any?>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        extractShare(intent)?.let { bufferedShare = it }
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeInitialShare" -> {
                        result.success(bufferedShare)
                        bufferedShare = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val share = extractShare(intent) ?: return
        val activeChannel = channel
        if (activeChannel != null) {
            activeChannel.invokeMethod("onShareReceived", share)
        } else {
            bufferedShare = share
        }
    }

    private fun extractShare(intent: Intent?): Map<String, Any?>? {
        if (intent?.action != Intent.ACTION_SEND) return null
        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: ""
        val image = readImage(streamUri(intent))
        if (text.isEmpty() && image == null) return null
        return mapOf("text" to text, "image" to image)
    }

    private fun streamUri(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    /** Reads the shared image, dropping it past the same 25 MiB cap the iOS extension enforces. */
    private fun readImage(uri: Uri?): ByteArray? {
        if (uri == null) return null
        return try {
            contentResolver.openInputStream(uri)?.use { input ->
                val buffer = ByteArrayOutputStream()
                val chunk = ByteArray(64 * 1024)
                var total = 0
                while (true) {
                    val read = input.read(chunk)
                    if (read < 0) break
                    total += read
                    if (total > MAX_IMAGE_BYTES) return null
                    buffer.write(chunk, 0, read)
                }
                if (buffer.size() == 0) null else buffer.toByteArray()
            }
        } catch (_: Exception) {
            null
        }
    }

    private companion object {
        const val CHANNEL = "oshilife/share"
        const val MAX_IMAGE_BYTES = 25 * 1024 * 1024
    }
}
