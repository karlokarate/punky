package app.punky.diabetes

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class BackgroundInitWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        Log.d("BackgroundInitWorker", "Hintergrunddienst wird initialisiert")
        // TODO: Sync/Netzwerk/Init-Tasks hier starten
        return Result.success()
    }
}
