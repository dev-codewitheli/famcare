package com.devcodewitheli.ring_alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * Keeps the app process alive (and unfrozen) while the alarm plays, as Android requires for
 * ongoing sound from the background. Its small notification has a "Stop" button; the ring
 * notification with "Coming!" is separate (flutter_local_notifications).
 */
class RingAlarmService : Service() {

    companion object {
        private const val TAG = "RingAlarm"
        private const val ACTION_START = "com.devcodewitheli.ring_alarm.START"
        private const val ACTION_STOP = "com.devcodewitheli.ring_alarm.STOP"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_MAX_MILLIS = "maxMillis"
        private const val CHANNEL_ID = "gate_ring_sound_v1"
        private const val NOTIFICATION_ID = 0x48424c // "HBL"

        fun start(context: Context, title: String, maxMillis: Long) {
            val intent = Intent(context, RingAlarmService::class.java)
                .setAction(ACTION_START)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_MAX_MILLIS, maxMillis)
            try {
                // Allowed from the background: a high-priority push (or a notification tap)
                // briefly lets an app start a foreground service.
                context.startForegroundService(intent)
            } catch (e: Exception) {
                // Not allowed right now on this phone: ring anyway, without the service.
                Log.w(TAG, "Foreground service not allowed, ringing without it: $e")
                AlarmPlayer.play(context, maxMillis) { AlarmPlayer.stop(context) }
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, RingAlarmService::class.java))
            AlarmPlayer.stop(context)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Someone is at the gate"
        val maxMillis = intent?.getLongExtra(EXTRA_MAX_MILLIS, 180_000L) ?: 180_000L
        // Must happen within seconds of startForegroundService.
        val notification = buildNotification(title)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        AlarmPlayer.play(this, maxMillis) { stopSelf() }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        AlarmPlayer.stop(this)
        super.onDestroy()
    }

    private fun buildNotification(title: String): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) == null) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Ring sound (Silent / DND)", NotificationManager.IMPORTANCE_LOW).apply {
                    description = "Shown while a gate ring plays on alarm volume"
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                },
            )
        }
        val stop = PendingIntent.getService(
            this, 0,
            Intent(this, RingAlarmService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val open = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 1, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
        // The app's status-bar bell (kept from resource shrinking via res/raw/keep.xml).
        val icon = resources.getIdentifier("ic_stat_bell", "drawable", packageName)
            .takeIf { it != 0 } ?: android.R.drawable.ic_lock_idle_alarm
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(icon)
            .setContentTitle(title)
            .setContentText("Ringing at alarm volume. Answer with \"Coming!\", or stop the sound here.")
            .setCategory(Notification.CATEGORY_ALARM)
            // Its own group, so Android doesn't bundle it with the ring notification and tuck
            // "Coming!" behind an extra tap.
            .setGroup("homebell_ring_sound")
            .setOngoing(true)
            .setContentIntent(open)
            .addAction(Notification.Action.Builder(null, "Stop sound", stop).build())
            .build()
    }
}
