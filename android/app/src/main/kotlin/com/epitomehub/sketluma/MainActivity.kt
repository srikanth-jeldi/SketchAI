package com.epitomehub.sketluma

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager
import android.os.Build
import android.content.Context

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sketchora/diagnostics")
            .setMethodCallHandler { call, result ->
                if (call.method != "previousExit") { result.notImplemented() }
                else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) { result.success(null) }
                else {
                    try {
                        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val exit = manager.getHistoricalProcessExitReasons(packageName, 0, 1).firstOrNull()
                        result.success(exit?.let { mapOf("reason" to it.reason, "status" to it.status, "description" to it.description, "timestamp" to it.timestamp, "pssKb" to it.pss, "device" to Build.MODEL, "androidApi" to Build.VERSION.SDK_INT) })
                    } catch (e: Exception) { result.error("diagnostics", "Exit history unavailable", null) }
                }
            }
    }
}
