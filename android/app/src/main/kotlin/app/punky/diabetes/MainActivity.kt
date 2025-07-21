package app.punky.diabetes

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "sms_channel"
        const val PERMISSION_REQUEST_CODE = 101
    }

    override fun getCachedEngineId(): String = MyApplication.ENGINE_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNecessaryPermissions()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val to = call.argument<String>("to").orEmpty()
                        val text = call.argument<String>("text").orEmpty()
                        try {
                            sendTextMessage(to, text)
                            result.success("sent")
                        } catch (e: Exception) {
                            result.error("SEND_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun sendTextMessage(to: String, message: String) {
        val smsManager = android.telephony.SmsManager.getDefault()
        smsManager.sendTextMessage(to, null, message, null, null)
        Toast.makeText(this, "SMS gesendet an $to", Toast.LENGTH_SHORT).show()
    }

    private fun requestNecessaryPermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val needed = arrayOf(
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.SEND_SMS,
            Manifest.permission.READ_SMS,
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.READ_EXTERNAL_STORAGE
        )

        val missing = needed.filter {
            checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }.toTypedArray()

        if (missing.isNotEmpty()) {
            requestPermissions(missing, PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val denied = permissions.zip(grantResults.toTypedArray())
                .filter { it.second != PackageManager.PERMISSION_GRANTED }
                .map { it.first }

            if (denied.isNotEmpty()) {
                Toast.makeText(
                    this,
                    "❌ Berechtigungen verweigert: ${denied.joinToString()}",
                    Toast.LENGTH_LONG
                ).show()
            }
        }

        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}