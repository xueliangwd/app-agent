package com.example.app_agent

import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private val channelName = "app_agent/native_bridge"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPlatformContext" -> {
                        result.success("Android ${Build.VERSION.RELEASE} · ${Build.MODEL}")
                    }
                    "generateSystemAIResponse" -> {
                        result.error(
                            "system_ai_unavailable",
                            "Android System AI currently requires device-side AICore / Gemini Nano support. This build exposes the provider entry and returns a clear fallback on unsupported devices.",
                            null
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
