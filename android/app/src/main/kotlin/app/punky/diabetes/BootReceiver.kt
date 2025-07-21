package app.punky.diabetes

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "BOOT_COMPLETED empfangen → starte BackgroundInitWorker")
            val workRequest = OneTimeWorkRequestBuilder<BackgroundInitWorker>().build()
            WorkManager.getInstance(context).enqueue(workRequest)
        }
    }
}
