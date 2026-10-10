package com.devcodewitheli.ring_alarm

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Log

/**
 * The ring itself: the phone's alarm sound, looping on the ALARM stream, plus vibration marked as
 * an alarm. That's what alarm clocks use, and Silent/vibrate mode doesn't mute it. One per
 * process, so whichever Flutter engine stops the ring stops this one.
 */
internal object AlarmPlayer {
    private const val TAG = "RingAlarm"

    private val alarm: AudioAttributes = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    // Same rhythm as the ring notification's vibration.
    private val pattern = longArrayOf(0, 800, 400, 800, 400, 800, 1200)

    private val handler = Handler(Looper.getMainLooper())
    private var player: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var focus: AudioFocusRequest? = null
    private var onTimeout: (() -> Unit)? = null

    val isPlaying: Boolean get() = player != null

    /** Starts ringing, or just restarts the safety timer if already ringing (each re-ring push). */
    fun play(context: Context, maxMillis: Long, onTimeout: () -> Unit) {
        this.onTimeout = onTimeout
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({ this.onTimeout?.invoke() }, maxMillis)
        if (player != null) return

        val app = context.applicationContext
        player = startSound(app)
        requestFocus(app)
        startVibration(app)
    }

    fun stop(context: Context) {
        handler.removeCallbacksAndMessages(null)
        onTimeout = null
        player?.runCatching { stop() }
        player?.release()
        player = null
        vibrator?.cancel()
        vibrator = null
        focus?.let { (context.getSystemService(Context.AUDIO_SERVICE) as AudioManager).abandonAudioFocusRequest(it) }
        focus = null
    }

    /** The phone's alarm sound; falls back to the ringtone or notification sound if it has none. */
    private fun startSound(context: Context): MediaPlayer? {
        val candidates = listOfNotNull(
            Settings.System.DEFAULT_ALARM_ALERT_URI,
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM),
            Settings.System.DEFAULT_RINGTONE_URI,
            Settings.System.DEFAULT_NOTIFICATION_URI,
        )
        for (uri in candidates) {
            val p = MediaPlayer()
            try {
                p.setAudioAttributes(alarm)
                p.setDataSource(context, uri)
                p.isLooping = true
                p.prepare()
                p.start()
                return p
            } catch (e: Exception) {
                Log.w(TAG, "Can't play $uri: $e")
                p.release()
            }
        }
        return null
    }

    /** Pauses music or videos while the gate rings. */
    private fun requestFocus(context: Context) {
        val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
            .setAudioAttributes(alarm)
            .build()
        (context.getSystemService(Context.AUDIO_SERVICE) as AudioManager).requestAudioFocus(request)
        focus = request
    }

    private fun startVibration(context: Context) {
        val v = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!v.hasVibrator()) return
        val effect = VibrationEffect.createWaveform(pattern, 1)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(effect, alarm)
        }
        vibrator = v
    }
}
