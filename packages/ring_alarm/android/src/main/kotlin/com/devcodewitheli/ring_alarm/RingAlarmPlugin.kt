package com.devcodewitheli.ring_alarm

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Registered in every Flutter engine of the app (UI, push handler, notification actions), so any
 * of them can start or stop the one ring; see lib/ring_alarm.dart.
 */
class RingAlarmPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "homebell/ring_alarm")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                RingAlarmService.start(
                    context,
                    call.argument<String>("title") ?: "Someone is at the gate",
                    call.argument<Number>("maxMillis")?.toLong() ?: 180_000L,
                )
                result.success(null)
            }
            "stop" -> {
                RingAlarmService.stop(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
