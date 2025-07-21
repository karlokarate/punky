package app.punky.diabetes

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MyApplication : Application() {

    companion object {
        const val ENGINE_ID = "main_engine"
    }

    override fun onCreate() {
        super.onCreate()
        // Headless FlutterEngine starten und Dart-Entrypoint ausführen
        val flutterEngine = FlutterEngine(this).apply {
            dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
        }
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
    }
}
