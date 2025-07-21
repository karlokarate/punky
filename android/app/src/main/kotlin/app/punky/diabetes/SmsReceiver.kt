package app.punky.diabetes

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.telephony.SmsMessage
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != "android.provider.Telephony.SMS_RECEIVED") return

        val bundle = intent.extras
        val pdus = bundle?.get("pdus") as? Array<*> ?: return
        val format = bundle.getString("format") ?: return

        val messages = pdus.mapNotNull { pdu ->
            (pdu as? ByteArray)?.let { SmsMessage.createFromPdu(it, format) }
        }

        val sender = messages.firstOrNull()?.originatingAddress.orEmpty()
        val body = messages.joinToString(separator = "") { it.messageBody }

        Log.d("SmsReceiver", "SMS von $sender: $body")

        // MethodChannel-Aufruf auf der vorgewärmten Engine
        FlutterEngineCache.getInstance()
            .get(MyApplication.ENGINE_ID)
            ?.dartExecutor
            ?.binaryMessenger
            ?.let { messenger ->
                MethodChannel(messenger, MainActivity.CHANNEL)
                    .invokeMethod("smsReceived", mapOf("from" to sender, "body" to body))
            }
    }
}
