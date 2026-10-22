package com.cyberskin.app.cyberskin_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/** 保持当前 Flutter/BLE 会话运行；不创建第二条 GATT 连接，不自动重启节奏。 */
class RhythmForegroundService : Service() {
    private var wakeLock: PowerManager.WakeLock? = null
    override fun onCreate() {
        super.onCreate()
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(
                "rhythm", "Device rhythm", NotificationManager.IMPORTANCE_LOW))
        }
        val intent = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, "rhythm") else Notification.Builder(this)
        val notification = builder.setContentTitle("Cyberskin rhythm")
            .setContentText("Device session active. Open Cyberskin to pause or end.")
            .setSmallIcon(android.R.drawable.ic_media_play).setOngoing(true)
            .setContentIntent(intent).build()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(4301, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else startForeground(4301, notification)
        wakeLock = (getSystemService(POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Cyberskin:Rhythm")
            .also { it.acquire(65 * 60 * 1000L) }
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int) = START_NOT_STICKY
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onTaskRemoved(rootIntent: Intent?) { stopSelf() }
    override fun onDestroy() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        super.onDestroy()
    }
}
