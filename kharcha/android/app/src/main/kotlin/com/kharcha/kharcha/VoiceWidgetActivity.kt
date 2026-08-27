package com.kharcha.kharcha

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs

/**
 * Transparent FlutterActivity that renders the custom Flutter voice overlay
 * screen (/widget-voice route) directly over the Android home screen.
 *
 * No native Android speech dialog is used — Flutter's own SpeechRecognitionService
 * handles microphone capture, and the WidgetVoiceOverlayScreen provides the full
 * custom UI: waveform, live transcription, AI parsing, editable fields, and save.
 *
 * When the user finishes (save or cancel), SystemNavigator.pop() finishes this
 * Activity and returns to the home screen without any app window lingering.
 */
class VoiceWidgetActivity : FlutterActivity() {

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun getInitialRoute(): String {
        return "/widget-voice"
    }
}
