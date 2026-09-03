package com.kharcha.kharcha

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.speech.RecognizerIntent
import android.widget.RemoteViews
import android.widget.Toast
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class VoiceWidgetActivity : Activity() {

    companion object {
        private const val SPEECH_REQUEST_CODE = 1001
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val TRANSACTIONS_KEY = "flutter.kharcha.transactions.v1"
        private const val SETTINGS_KEY = "flutter.kharcha.settings.v1"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Launch native Android voice speech recognition immediately
        try {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak your expense (e.g. Lunch 450)")
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }
            startActivityForResult(intent, SPEECH_REQUEST_CODE)
        } catch (e: Exception) {
            Toast.makeText(this, "Voice recognition not available on this device", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SPEECH_REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                val results = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val spokenText = results?.firstOrNull() ?: ""

                if (spokenText.isNotBlank()) {
                    saveVoiceExpense(spokenText)
                } else {
                    Toast.makeText(this, "No voice input recognized", Toast.LENGTH_SHORT).show()
                }
            } else if (resultCode != RESULT_CANCELED) {
                Toast.makeText(this, "Voice input stopped", Toast.LENGTH_SHORT).show()
            }
            finish()
            overridePendingTransition(0, 0)
        } else {
            finish()
            overridePendingTransition(0, 0)
        }
    }

    private fun saveVoiceExpense(spokenText: String) {
        try {
            val parsed = VoiceTransactionParser.parse(spokenText)
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val now = Date()
            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
                timeZone = TimeZone.getDefault()
            }
            val utcFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }

            val dateStr = isoFormat.format(now)
            val utcStr = utcFormat.format(now)
            val txId = "tx_${System.currentTimeMillis()}"

            // Build Transaction JSON matching Kharcha model
            val txJson = JSONObject().apply {
                put("id", txId)
                put("remoteId", JSONObject.NULL)
                put("merchant", parsed.merchant)
                put("category", parsed.category)
                put("amount", parsed.amount)
                put("date", dateStr)
                put("note", parsed.rawText)
                put("method", "Cash")
                put("source", "voice")
                put("isIncome", parsed.isIncome)
                put("syncState", "pendingCreate")
                put("syncFailure", JSONObject.NULL)
                put("attachmentIds", JSONArray())
                put("lastSyncedAt", JSONObject.NULL)
                put("updatedAt", utcStr)
                put("deletedAt", JSONObject.NULL)
            }

            // Load existing transactions JSON array from Flutter shared prefs
            val existingRaw = prefs.getString(TRANSACTIONS_KEY, null)
            val transactionsArray = if (!existingRaw.isNullOrEmpty()) {
                try {
                    JSONArray(existingRaw)
                } catch (e: Exception) {
                    JSONArray()
                }
            } else {
                JSONArray()
            }

            // Prepend new transaction
            val newArray = JSONArray()
            newArray.put(txJson)
            for (i in 0 until transactionsArray.length()) {
                newArray.put(transactionsArray.getJSONObject(i))
            }

            // Save to Flutter shared prefs
            prefs.edit().putString(TRANSACTIONS_KEY, newArray.toString()).apply()

            // Calculate Today's Spent Total for widget
            val currency = readCurrencySymbol(prefs)
            var todayTotal = 0.0
            var todayCount = 0

            val calToday = Calendar.getInstance()
            val todayYear = calToday.get(Calendar.YEAR)
            val todayMonth = calToday.get(Calendar.MONTH)
            val todayDay = calToday.get(Calendar.DAY_OF_MONTH)

            val calTx = Calendar.getInstance()
            for (i in 0 until newArray.length()) {
                val item = newArray.getJSONObject(i)
                val isIncome = item.optBoolean("isIncome", false)
                val itemDateStr = item.optString("date", "")
                if (!isIncome && itemDateStr.isNotEmpty()) {
                    try {
                        val d = isoFormat.parse(itemDateStr)
                        if (d != null) {
                            calTx.time = d
                            if (calTx.get(Calendar.YEAR) == todayYear &&
                                calTx.get(Calendar.MONTH) == todayMonth &&
                                calTx.get(Calendar.DAY_OF_MONTH) == todayDay
                            ) {
                                todayTotal += item.optDouble("amount", 0.0)
                                todayCount++
                            }
                        }
                    } catch (e: Exception) {
                        // ignore malformed date
                    }
                }
            }

            val formatter = NumberFormat.getNumberInstance(Locale.US)
            val formattedAmount = "$currency ${formatter.format(todayTotal.toLong())}"
            val countText = if (todayCount == 1) "1 expense today" else "$todayCount expenses today"

            // Save to Widget storage
            prefs.edit()
                .putString("today_spent", formattedAmount)
                .putString("today_count", countText)
                .putString("currency", currency)
                .apply()

            // Update the Home Screen Widget directly
            updateHomeScreenWidget(this, formattedAmount, countText, currency)

            // Show Toast right on home screen
            val amountFormatted = formatter.format(parsed.amount.toLong())
            Toast.makeText(
                this,
                "✓ Added $currency $amountFormatted for ${parsed.merchant}",
                Toast.LENGTH_LONG
            ).show()

        } catch (e: Exception) {
            Toast.makeText(this, "Error saving expense: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun readCurrencySymbol(prefs: SharedPreferences): String {
        val settingsRaw = prefs.getString(SETTINGS_KEY, null)
        if (!settingsRaw.isNullOrEmpty()) {
            try {
                val json = JSONObject(settingsRaw)
                val symbol = json.optString("currencySymbol", "")
                if (symbol.isNotBlank()) return symbol
            } catch (e: Exception) {
                // fallback
            }
        }
        return "Rs."
    }

    private fun updateHomeScreenWidget(
        context: Context,
        todayAmount: String,
        todayCount: String,
        currency: String
    ) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val thisWidget = ComponentName(context, KharchaWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kharcha_widget_layout).apply {
                setTextViewText(R.id.widget_today_amount, todayAmount)
                setTextViewText(R.id.widget_today_count, todayCount)
                setTextViewText(R.id.widget_currency_tag, currency)

                // Voice Action -> Native VoiceWidgetActivity (keeps app closed!)
                val voiceIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    VoiceWidgetActivity::class.java,
                    null
                )
                setOnClickPendingIntent(R.id.widget_action_voice, voiceIntent)

                // Scan Action
                val scanIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("kharcha://capture/scan")
                )
                setOnClickPendingIntent(R.id.widget_action_scan, scanIntent)

                // Manual Action
                val manualIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("kharcha://capture/manual")
                )
                setOnClickPendingIntent(R.id.widget_action_manual, manualIntent)

                // Card Click -> Open full app
                val cardIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    android.net.Uri.parse("kharcha://home")
                )
                setOnClickPendingIntent(R.id.widget_container, cardIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
