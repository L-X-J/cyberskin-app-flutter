package com.cyberskin.app.cyberskin_app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // BLE 后台生命周期通道：start / stop 前台服务。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cyberskin/rhythm_background")
            .setMethodCallHandler { call, result ->
                val intent = Intent(this, RhythmForegroundService::class.java)
                try {
                    when (call.method) {
                        "start" -> {
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent)
                            else startService(intent)
                            result.success(null)
                        }
                        "stop" -> {
                            stopService(intent)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("rhythm_background", "Unable to start the device background session.", null)
                }
            }

        // Now Playing 通道：接收播放快照并更新 MediaStyle 通知。
        // start 和 update 携带 title / totalSeconds / remainingSeconds / phase。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cyberskin/now_playing")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "start", "update" -> {
                            val title = call.argument<String>("title") ?: "Cyberskin"
                            val total = call.argument<Int>("totalSeconds") ?: 0
                            val remaining = call.argument<Int>("remainingSeconds") ?: 0
                            val phase = call.argument<String>("phase") ?: "running"
                            // 若服务未在运行则先启动，再推送最新数据。
                            val intent = Intent(this, RhythmForegroundService::class.java).apply {
                                putExtra(RhythmForegroundService.EXTRA_TITLE, title)
                                putExtra(RhythmForegroundService.EXTRA_TOTAL, total)
                                putExtra(RhythmForegroundService.EXTRA_REMAINING, remaining)
                                putExtra(RhythmForegroundService.EXTRA_PHASE, phase)
                            }
                            if (Build.VERSION.SDK_INT >= 26) startForegroundService(intent)
                            else startService(intent)
                            result.success(null)
                        }
                        "end" -> {
                            // 仅更新通知状态；服务生命周期由 rhythm_background 通道管理。
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("now_playing", "Unable to update playback notification.", null)
                }
            }
    }
}
