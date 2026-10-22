package com.cyberskin.app.cyberskin_app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cyberskin/rhythm_background")
            .setMethodCallHandler { call, result ->
                val intent = Intent(this, RhythmForegroundService::class.java)
                try {
                    when (call.method) {
                        "start" -> {
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent) else startService(intent)
                            result.success(null)
                        }
                        "stop" -> { stopService(intent); result.success(null) }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("rhythm_background", "Unable to start the device background session.", null)
                }
            }
    }
}
