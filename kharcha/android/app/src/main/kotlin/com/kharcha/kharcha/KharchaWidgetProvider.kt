package com.kharcha.kharcha

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

class KharchaWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val TRANSACTIONS_KEY = "flutter.kharcha.transactions.v1"
        private const val SETTINGS_KEY = "flutter.kharcha.settings.v1"

        data class WidgetMetrics(val amount: String, val count: String, val currency: String)

        fun calculateTodayMetrics(context: Context): WidgetMetrics {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // 1. Read Currency Symbol
            var currency = "Rs."
            val settingsRaw = prefs.getString(SETTINGS_KEY, null)
            if (!settingsRaw.isNullOrEmpty()) {
                try {
                    val json = JSONObject(settingsRaw)
                    val symbol = json.optString("currencySymbol", "")
                    if (symbol.isNotBlank()) currency = symbol
                } catch (e: Exception) {}
            }

            // 2. Read and compute Today's Expenses dynamically from transactions
            val rawTx = prefs.getString(TRANSACTIONS_KEY, null)
            var todayTotal = 0.0
            var todayCount = 0

            val calToday = Calendar.getInstance()
            val todayYear = calToday.get(Calendar.YEAR)
            val todayMonth = calToday.get(Calendar.MONTH)
            val todayDay = calToday.get(Calendar.DAY_OF_MONTH)

            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
                timeZone = TimeZone.getDefault()
            }
            val calTx = Calendar.getInstance()

            if (!rawTx.isNullOrEmpty()) {
                try {
                    val txArray = JSONArray(rawTx)
                    for (i in 0 until txArray.length()) {
                        val item = txArray.getJSONObject(i)
                        val isIncome = item.optBoolean("isIncome", false)
                        val dateStr = item.optString("date", "")
                        if (!isIncome && dateStr.isNotEmpty()) {
                            try {
                                val d = isoFormat.parse(dateStr)
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
                            } catch (e: Exception) {}
                        }
                    }
                } catch (e: Exception) {}
            }

            val formatter = NumberFormat.getNumberInstance(Locale.US)
            val formattedAmount = "$currency ${formatter.format(todayTotal.toLong())}"
            val countText = if (todayCount == 1) "1 expense today" else "$todayCount expenses today"

            // Cache to SharedPreferences
            prefs.edit()
                .putString("today_spent", formattedAmount)
                .putString("today_count", countText)
                .putString("currency", currency)
                .apply()

            return WidgetMetrics(formattedAmount, countText, currency)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        // Automatically refresh when date, time, timezone, or system theme changes
        if (action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_CONFIGURATION_CHANGED
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, KharchaWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            onUpdate(context, appWidgetManager, appWidgetIds, prefs)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        // Recalculate metrics dynamically based on current day and budget
        val metrics = WidgetDataHelper.calculateMetrics(context)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kharcha_widget_layout).apply {
                setTextViewText(R.id.widget_today_amount, metrics.todayAmount)
                setTextViewText(R.id.widget_today_count, metrics.todayCount)
                setTextViewText(R.id.widget_currency_tag, metrics.currency)
                setProgressBar(R.id.widget_budget_progress, 100, metrics.budgetProgressInt, false)
                setTextViewText(R.id.widget_remaining_budget, metrics.remainingBudgetFormatted)

                // Voice Action -> Instant Native Voice Bottom Sheet Dialog
                val voiceIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    VoiceWidgetActivity::class.java,
                    null
                )
                setOnClickPendingIntent(R.id.widget_action_voice, voiceIntent)

                // Scan Action -> Instant Native Scan Activity
                val scanIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    ScanWidgetActivity::class.java,
                    null
                )
                setOnClickPendingIntent(R.id.widget_action_scan, scanIntent)

                // Manual Action -> Instant Native Manual Bottom Sheet
                val manualIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    ManualWidgetActivity::class.java,
                    null
                )
                setOnClickPendingIntent(R.id.widget_action_manual, manualIntent)

                // Whole Card Click (Deep Link: kharcha://home)
                val cardIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("kharcha://home")
                )
                setOnClickPendingIntent(R.id.widget_container, cardIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
