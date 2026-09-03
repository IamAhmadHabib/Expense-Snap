package com.kharcha.kharcha

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val syncChannelName = "com.kharcha.app/sync"
    private var syncChannel: MethodChannel? = null
    private var isReceiverRegistered = false

    private val transactionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            syncChannel?.invokeMethod("onTransactionAdded", null)
            updateAllWidgets()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        syncChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, syncChannelName)
    }

    override fun onResume() {
        super.onResume()
        if (!isReceiverRegistered) {
            val filter = IntentFilter("com.kharcha.kharcha.TRANSACTION_ADDED")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(transactionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(transactionReceiver, filter)
            }
            isReceiverRegistered = true
        }
        // Notify Flutter to reload storage on every resume
        syncChannel?.invokeMethod("onTransactionAdded", null)
        updateAllWidgets()
    }

    override fun onPause() {
        super.onPause()
        if (isReceiverRegistered) {
            try {
                unregisterReceiver(transactionReceiver)
            } catch (e: Exception) {}
            isReceiverRegistered = false
        }
    }

    private fun updateAllWidgets() {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val widget4x1 = ComponentName(this, KharchaWidgetProvider::class.java)
            val ids4x1 = appWidgetManager.getAppWidgetIds(widget4x1)
            if (ids4x1.isNotEmpty()) {
                KharchaWidgetProvider().onUpdate(this, appWidgetManager, ids4x1, prefs)
            }

            val widget2x2 = ComponentName(this, KharchaWidget2x2Provider::class.java)
            val ids2x2 = appWidgetManager.getAppWidgetIds(widget2x2)
            if (ids2x2.isNotEmpty()) {
                KharchaWidget2x2Provider().onUpdate(this, appWidgetManager, ids2x2, prefs)
            }

            val widget4x2 = ComponentName(this, KharchaWidget4x2Provider::class.java)
            val ids4x2 = appWidgetManager.getAppWidgetIds(widget4x2)
            if (ids4x2.isNotEmpty()) {
                KharchaWidget4x2Provider().onUpdate(this, appWidgetManager, ids4x2, prefs)
            }
        } catch (e: Exception) {}
    }
}
