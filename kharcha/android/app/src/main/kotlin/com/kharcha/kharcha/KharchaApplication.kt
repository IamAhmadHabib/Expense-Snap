package com.kharcha.kharcha

import android.app.Application
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class KharchaApplication : Application() {

    companion object {
        const val VOICE_ENGINE_ID = "kharcha_voice_overlay_engine"
    }

    override fun onCreate() {
        super.onCreate()
        prewarmVoiceEngine()
    }

    fun prewarmVoiceEngine() {
        try {
            val flutterLoader = FlutterInjector.instance().flutterLoader()
            if (!flutterLoader.initialized()) {
                flutterLoader.startInitialization(this)
            }
            flutterLoader.ensureInitializationComplete(this, null)

            // Destroy previous engine if present
            FlutterEngineCache.getInstance().get(VOICE_ENGINE_ID)?.destroy()

            val engine = FlutterEngine(this)

            // Configure initial route directly to the voice overlay
            engine.navigationChannel.setInitialRoute("/widget-voice")

            // Execute default entry point (main.dart) which triggers the ultra-fast-path
            // and initializes the real WidgetVoiceOverlayScreen with full audio, permissions,
            // repository, and home-widget sync!
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )

            // Cache for instant sub-50ms attachment
            FlutterEngineCache.getInstance().put(VOICE_ENGINE_ID, engine)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
