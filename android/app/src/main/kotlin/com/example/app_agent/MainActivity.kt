package com.example.app_agent

import android.os.Build
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val channelName = "app_agent/native_bridge"
    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val generativeModel by lazy { Generation.getClient() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPlatformContext" -> {
                        result.success("Android ${Build.VERSION.RELEASE} · ${Build.MODEL}")
                    }
                    "generateSystemAIResponse" -> {
                        val prompt = call.argument<String>("prompt").orEmpty()
                        handleSystemAi(prompt, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleSystemAi(prompt: String, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error(
                "system_ai_unsupported",
                "Android System AI requires Android 8.0 (API 26) or later.",
                null
            )
            return
        }

        activityScope.launch {
            try {
                var status = generativeModel.checkStatus()
                when (status) {
                    FeatureStatus.UNAVAILABLE -> {
                        result.error(
                            "system_ai_unavailable",
                            "Gemini Nano / AICore is unavailable on this device. Android 官方文档说明这通常表示设备不支持、AICore 尚未完成初始化，或设备处于不受支持状态。",
                            null
                        )
                        return@launch
                    }
                    FeatureStatus.DOWNLOADABLE -> {
                        generativeModel.download().collect { }
                        status = generativeModel.checkStatus()
                    }
                    FeatureStatus.DOWNLOADING -> {
                        result.error(
                            "system_ai_downloading",
                            "System AI model is still downloading via AICore. Please wait and try again.",
                            null
                        )
                        return@launch
                    }
                    FeatureStatus.AVAILABLE -> Unit
                }

                if (status != FeatureStatus.AVAILABLE) {
                    result.error(
                        "system_ai_unavailable",
                        "System AI is not ready yet. Current feature status: $status",
                        null
                    )
                    return@launch
                }

                val response = generativeModel.generateContent(prompt)
                val text = response.candidates.firstOrNull()?.text?.trim().orEmpty()
                if (text.isEmpty()) {
                    result.error(
                        "system_ai_empty",
                        "System AI returned an empty response.",
                        null
                    )
                    return@launch
                }
                result.success(text)
            } catch (error: Exception) {
                result.error(
                    "system_ai_failed",
                    "Android System AI generation failed: ${error.message}",
                    null
                )
            }
        }
    }

    override fun onDestroy() {
        generativeModel.close()
        activityScope.cancel()
        super.onDestroy()
    }
}
