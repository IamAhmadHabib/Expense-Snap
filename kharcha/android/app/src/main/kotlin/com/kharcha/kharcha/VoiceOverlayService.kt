package com.kharcha.kharcha

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.WindowManager
import android.widget.FrameLayout
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterSurfaceView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class VoiceOverlayService : Service() {

    companion object {
        private const val CHANNEL_NAME = "com.kharcha.voice_overlay/bridge"
        private const val NOTIFICATION_CHANNEL_ID = "kharcha_voice_overlay_service"
        private const val NOTIFICATION_ID = 1010
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val TRANSACTIONS_KEY = "flutter.kharcha.transactions.v1"
    }

    private var windowManager: WindowManager? = null
    private var overlayRoot: FrameLayout? = null
    private var flutterView: FlutterView? = null
    private var methodChannel: MethodChannel? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildForegroundNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            // Permission fallback: Launch VoiceWidgetActivity with cached engine
            val activityIntent = Intent(this, VoiceWidgetActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            startActivity(activityIntent)
            stopSelf()
            return START_NOT_STICKY
        }

        if (overlayRoot == null) {
            setupFloatingWindow()
        }
        return START_NOT_STICKY
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupFloatingWindow() {
        val engine = FlutterEngineCache.getInstance().get(KharchaApplication.VOICE_ENGINE_ID)
        if (engine == null) {
            // Fallback to activity if engine not cached
            val activityIntent = Intent(this, VoiceWidgetActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            startActivity(activityIntent)
            stopSelf()
            return
        }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        // Root container intercepting dismiss taps outside the modal card
        overlayRoot = FrameLayout(this).apply {
            setOnClickListener {
                dismissOverlay()
            }
        }

        // Dedicated FlutterView attached to FlutterSurfaceView with transparent buffer rendering
        val surfaceView = FlutterSurfaceView(this, true)
        flutterView = FlutterView(this, surfaceView).apply {
            attachToFlutterEngine(engine)
        }

        val frameParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        )
        overlayRoot?.addView(flutterView, frameParams)

        // Overlay window parameters matching production floating dialog conventions
        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val windowParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        windowManager?.addView(overlayRoot, windowParams)

        // MethodChannel communication with the isolated Dart entry point
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "dismiss" -> {
                    dismissOverlay()
                    result.success(true)
                }
                "commitTransaction" -> {
                    val amount = call.argument<Double>("amount") ?: 0.0
                    val merchant = call.argument<String>("merchant") ?: "General"
                    val category = call.argument<String>("category") ?: "Other"
                    val method = call.argument<String>("method") ?: "Cash"
                    val note = call.argument<String>("note") ?: ""

                    persistTransactionDirectly(amount, merchant, category, method, note)
                    dismissOverlay()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Notify Dart that the native surface is attached and ready
        methodChannel?.invokeMethod("onOverlayPresented", null)
    }

    private fun persistTransactionDirectly(
        amount: Double,
        merchant: String,
        category: String,
        method: String,
        note: String
    ) {
        try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val now = Date()
            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
                timeZone = TimeZone.getDefault()
            }
            val utcFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }

            val txJson = JSONObject().apply {
                put("id", "tx_${System.currentTimeMillis()}")
                put("remoteId", JSONObject.NULL)
                put("merchant", merchant)
                put("category", category)
                put("amount", amount)
                put("date", isoFormat.format(now))
                put("note", note)
                put("method", method)
                put("source", "voice")
                put("isIncome", false)
                put("syncState", "pendingCreate")
                put("syncFailure", JSONObject.NULL)
                put("attachmentIds", JSONArray())
                put("lastSyncedAt", JSONObject.NULL)
                put("updatedAt", utcFormat.format(now))
                put("deletedAt", JSONObject.NULL)
            }

            val rawList = prefs.getString(TRANSACTIONS_KEY, null)
            val jsonArray = if (!rawList.isNullOrEmpty()) JSONArray(rawList) else JSONArray()
            val updated = JSONArray().apply {
                put(txJson)
                for (i in 0 until jsonArray.length()) {
                    put(jsonArray.getJSONObject(i))
                }
            }

            prefs.edit().putString(TRANSACTIONS_KEY, updated.toString()).apply()

            // Trigger widget metrics refresh
            val updateIntent = Intent(this, KharchaWidgetProvider::class.java).apply {
                action = android.appwidget.AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            sendBroadcast(updateIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun dismissOverlay() {
        try {
            flutterView?.detachFromFlutterEngine()
            if (overlayRoot != null && overlayRoot?.isAttachedToWindow == true) {
                windowManager?.removeViewImmediate(overlayRoot)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            overlayRoot = null
            flutterView = null
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Kharcha Quick Capture",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Capturing your expense from the home screen"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Kharcha Voice")
            .setContentText("Listening...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        dismissOverlay()
        super.onDestroy()
    }
}
