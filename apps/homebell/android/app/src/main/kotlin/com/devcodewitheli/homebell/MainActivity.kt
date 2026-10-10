package com.devcodewitheli.homebell

import android.app.AppOpsManager
import android.app.Notification
import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Reliability checks and OEM settings screens the Flutter plugins don't expose;
        // see lib/setup/device_settings.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "homebell/device_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canUseFullScreenIntent" -> result.success(canUseFullScreenIntent())
                    "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                    "manufacturer" -> result.success(Build.MANUFACTURER)
                    "alarmVolumePercent" -> result.success(alarmVolumePercent())
                    "ringChannelOk" -> result.success(
                        ringChannelOk(call.argument<String>("channelId")!!, call.argument<Boolean>("requireSound") ?: true))
                    "miuiOpAllowed" -> result.success(miuiOpAllowed(call.argument<Int>("op")!!))
                    "requestIgnoreBatteryOptimizations" -> {
                        // Shows the system "Let app always run in background?" dialog.
                        startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "openAppSettings" -> {
                        openAppDetails()
                        result.success(null)
                    }
                    "openSoundSettings" -> result.success(tryStart(Intent(Settings.ACTION_SOUND_SETTINGS)))
                    "openChannelSettings" -> {
                        val channelId = call.argument<String>("channelId")!!
                        result.success(tryStart(Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            .putExtra(Settings.EXTRA_CHANNEL_ID, channelId)) || openAppDetails())
                    }
                    "openAutostartSettings" -> result.success(openFirst(AUTOSTART_SCREENS))
                    "openOemPermissions" -> result.success(openOemPermissions())
                    "openOemBatterySettings" -> result.success(openFirst(BATTERY_SCREENS))
                    else -> result.notImplemented()
                }
            }
    }

    /** Android 14+ lets users revoke full-screen alerts for apps that aren't calling or alarm apps. */
    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return manager.canUseFullScreenIntent()
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    /** Gate rings play on the alarm stream, so a muted alarm volume means a silent ring. */
    private fun alarmVolumePercent(): Int {
        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val max = audio.getStreamMaxVolume(AudioManager.STREAM_ALARM).coerceAtLeast(1)
        return audio.getStreamVolume(AudioManager.STREAM_ALARM) * 100 / max
    }

    /**
     * The user can turn a channel's sound or pop-up off in system settings; this catches that.
     * Null if the channel doesn't exist yet. [requireSound] is false for the Silent/DND channel,
     * which is silent on purpose (the sound plays on the alarm stream instead).
     */
    private fun ringChannelOk(channelId: String, requireSound: Boolean): Boolean? {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = manager.getNotificationChannel(channelId) ?: return null
        return channel.importance >= NotificationManager.IMPORTANCE_HIGH &&
            (!requireSound || channel.sound != null) &&
            channel.lockscreenVisibility != Notification.VISIBILITY_SECRET
    }

    /**
     * Xiaomi keeps Autostart (10008), "Show on Lock screen" (10020) and "Display pop-up windows
     * while running in the background" (10021) as app-ops. checkOpNoThrow(int, int, String) is a
     * hidden API, so this is best effort: null means "can't tell", and the setup screen falls back
     * to asking the user.
     */
    private fun miuiOpAllowed(op: Int): Boolean? {
        if (!Build.MANUFACTURER.equals("xiaomi", ignoreCase = true)) return null
        return try {
            val ops = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val check = AppOpsManager::class.java.getMethod(
                "checkOpNoThrow", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType, String::class.java)
            check.invoke(ops, op, Process.myUid(), packageName) as Int == AppOpsManager.MODE_ALLOWED
        } catch (_: Exception) {
            null
        }
    }

    private fun openAppDetails(): Boolean = tryStart(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
        Uri.fromParts("package", packageName, null)))

    /**
     * Xiaomi's hidden "Other permissions" page, where "Show on Lock screen" and "Display pop-up
     * windows while running in the background" live. Falls back to the app's settings.
     */
    private fun openOemPermissions(): Boolean {
        val miui = Intent("miui.intent.action.APP_PERM_EDITOR").putExtra("extra_pkgname", packageName)
        val editors = listOf(
            ComponentName("com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity"),
            ComponentName("com.miui.securitycenter", "com.miui.permcenter.permissions.AppPermissionsEditorActivity"),
        )
        return editors.any { tryStart(Intent(miui).setComponent(it)) } || tryStart(miui) || openAppDetails()
    }

    /**
     * OEM screens aren't public APIs and move between OS versions, so try the known ones and fall
     * back to the app's settings. Returns true if a brand-specific screen opened.
     */
    private fun openFirst(screens: List<ComponentName>): Boolean {
        if (screens.any { tryStart(Intent().setComponent(it)) }) return true
        openAppDetails()
        return false
    }

    private fun tryStart(intent: Intent): Boolean = try {
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (_: Exception) {
        // Not on this brand or OS version.
        false
    }

    private companion object {
        /** Without autostart, these brands won't let a closed app wake up for a push. */
        val AUTOSTART_SCREENS = listOf(
            ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
            ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"),
            ComponentName("com.oplus.safecenter", "com.oplus.safecenter.permission.startup.StartupAppListActivity"),
            ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
            ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"),
            ComponentName("com.transsion.phonemaster", "com.cyin.himgr.autostart.AutoStartActivity"),
        )

        /** Where each brand hides "let this app run in the background". */
        val BATTERY_SCREENS = listOf(
            ComponentName("com.samsung.android.lool", "com.samsung.android.sm.battery.ui.BatteryActivity"),
            ComponentName("com.samsung.android.sm", "com.samsung.android.sm.battery.ui.BatteryActivity"),
            ComponentName("com.vivo.abe", "com.vivo.applicationbehaviorengine.ui.ExcessivePowerManagerActivity"),
            ComponentName("com.coloros.oppoguardelf", "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity"),
            ComponentName("com.miui.powerkeeper", "com.miui.powerkeeper.ui.HiddenAppsConfigActivity"),
        )
    }
}
