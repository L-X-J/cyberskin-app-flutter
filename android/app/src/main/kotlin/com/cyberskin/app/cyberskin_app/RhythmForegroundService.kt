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
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat as MediaNotificationCompat

/**
 * 保持当前 Flutter/BLE 会话运行并向系统呈现 MediaStyle 通知。
 *
 * 不创建第二条 GATT 连接，不自动重启播放。通知可通过 [updatePlayback] 实时刷新。
 */
class RhythmForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "rhythm"
        private const val NOTIFICATION_ID = 4301
        const val EXTRA_TITLE = "title"
        const val EXTRA_TOTAL = "total_seconds"
        const val EXTRA_REMAINING = "remaining_seconds"
        const val EXTRA_PHASE = "phase"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var mediaSession: MediaSessionCompat? = null
    private var currentTitle: String = "Cyberskin"
    private var currentPhase: String = "running"
    private var currentTotal: Int = 0
    private var currentRemaining: Int = 0

    override fun onCreate() {
        super.onCreate()
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Device playback", NotificationManager.IMPORTANCE_LOW)
            )
        }
        // MediaSession 只持有控制通道；Cyberskin 设备通过 BLE 控制，无需实际音频队列。
        val session = MediaSessionCompat(this, "CyberskinPlayback").apply {
            isActive = true
        }
        mediaSession = session

        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= 29) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        wakeLock = (getSystemService(POWER_SERVICE) as PowerManager)
            .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Cyberskin:Rhythm")
            .also { it.acquire(65 * 60 * 1000L) }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 后续启动携带最新播放数据；首次启动（从 onCreate）只用默认值。
        intent?.let {
            currentTitle = it.getStringExtra(EXTRA_TITLE) ?: currentTitle
            currentTotal = it.getIntExtra(EXTRA_TOTAL, currentTotal)
            currentRemaining = it.getIntExtra(EXTRA_REMAINING, currentRemaining)
            currentPhase = it.getStringExtra(EXTRA_PHASE) ?: currentPhase
        }
        refreshNotification()
        return START_NOT_STICKY
    }

    /** 从 MainActivity 同步更新播放进度和标题，无需重启服务。 */
    fun updatePlayback(title: String, totalSeconds: Int, remainingSeconds: Int, phase: String) {
        currentTitle = title
        currentTotal = totalSeconds
        currentRemaining = remainingSeconds
        currentPhase = phase
        refreshNotification()
    }

    private fun buildNotification(): Notification {
        val launchIntent = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val session = mediaSession!!

        // MediaMetadata 驱动 MediaStyle 标题和子标题区域。
        val elapsed = (currentTotal - currentRemaining).coerceAtLeast(0).toLong()
        val totalMs = currentTotal.toLong()
        session.setMetadata(
            MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, currentTitle)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, "Cyberskin")
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, totalMs * 1000)
                .build()
        )
        val stateBuilder = PlaybackStateCompat.Builder()
            .setActions(PlaybackStateCompat.ACTION_STOP)
        when (currentPhase) {
            "running" -> stateBuilder
                .setState(PlaybackStateCompat.STATE_PLAYING, elapsed * 1000, 1f)
            "paused" -> stateBuilder
                .setState(PlaybackStateCompat.STATE_PAUSED, elapsed * 1000, 0f)
            "interrupted" -> stateBuilder
                .setState(PlaybackStateCompat.STATE_ERROR, elapsed * 1000, 0f)
            else -> stateBuilder
                .setState(PlaybackStateCompat.STATE_PLAYING, elapsed * 1000, 1f)
        }
        session.setPlaybackState(stateBuilder.build())

        val progressText = if (currentTotal > 0) {
            val rem = currentRemaining
            val min = rem / 60; val sec = rem % 60
            "%d:%02d remaining".format(min, sec)
        } else {
            "Session active"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(currentTitle)
            .setContentText(progressText)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .setContentIntent(launchIntent)
            .setStyle(
                MediaNotificationCompat.MediaStyle()
                    .setMediaSession(session.sessionToken)
                    .setShowActionsInCompactView()
            )
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun refreshNotification() {
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, buildNotification())
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTaskRemoved(rootIntent: Intent?) {
        stopSelf()
    }

    override fun onDestroy() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        mediaSession?.release()
        mediaSession = null
        super.onDestroy()
    }
}
