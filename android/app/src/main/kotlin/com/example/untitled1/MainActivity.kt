package com.example.untitled1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Cache den Engine unter dem Namen „main“ für Zugriff durch SmsReceiver
        FlutterEngineCache.getInstance().put("main", flutterEngine)
        super.configureFlutterEngine(flutterEngine)
    }
}
