package com.kharcha.kharcha

import android.content.BroadcastReceiver
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
}
