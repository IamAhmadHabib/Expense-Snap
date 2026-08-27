package com.kharcha.kharcha

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngineCache

class VoiceWidgetActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        overridePendingTransition(0, 0)
    }

    override fun finish() {
        super.finish()
        overridePendingTransition(0, 0)
    }

    override fun getCachedEngineId(): String? {
        return if (FlutterEngineCache.getInstance().contains(KharchaApplication.VOICE_ENGINE_ID)) {
            KharchaApplication.VOICE_ENGINE_ID
        } else {
            null
        }
    }

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun getInitialRoute(): String {
        return "/widget-voice"
    }

    override fun shouldDestroyEngineWithHost(): Boolean {
        // Destroy used engine instance on dismiss to prevent stale state
        return true
    }

    override fun onDestroy() {
        super.onDestroy()
        // Pre-warm a fresh engine in the background for the next widget tap
        (application as? KharchaApplication)?.prewarmVoiceEngine()
    }
}
