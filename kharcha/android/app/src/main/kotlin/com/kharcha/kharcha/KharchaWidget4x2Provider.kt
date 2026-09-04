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

class KharchaWidget4x2Provider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_CONFIGURATION_CHANGED
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, KharchaWidget4x2Provider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            onUpdate(context, appWidgetManager, appWidgetIds, prefs)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val metrics = WidgetDataHelper.calculateMetrics(context)
        val chartBitmap = WidgetDataHelper.drawThisWeekChart(context, metrics.thisWeekTotals, metrics.todayDayIndex, 145, 52)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kharcha_widget_4x2_layout).apply {
                setTextViewText(R.id.widget_4x2_today_amount, metrics.todayAmount)
                setTextViewText(R.id.widget_4x2_today_count, metrics.todayCount)
                setTextViewText(R.id.widget_4x2_currency_tag, metrics.currency)
                setTextViewText(R.id.widget_4x2_remaining_budget, metrics.remainingBudgetFormatted)
                setTextViewText(R.id.widget_4x2_budget_percent, "${metrics.budgetProgressInt}% spent")
                setProgressBar(R.id.widget_4x2_budget_progress, 100, metrics.budgetProgressInt, false)
                setImageViewBitmap(R.id.widget_4x2_weekly_chart, chartBitmap)

                // Voice Action -> Instant Native Voice Bottom Sheet Dialog
                val voiceIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    VoiceWidgetActivity::class.java,
                    null
                )
                setOnClickPendingIntent(R.id.widget_4x2_action_voice, voiceIntent)

                // Scan Action -> Instant Native Scan Activity
                val scanIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    ScanWidgetActivity::class.java,
                    null
                )
                setOnClickPendingIntent(R.id.widget_4x2_action_scan, scanIntent)

                // Manual Action -> Instant Native Manual Bottom Sheet
                val manualIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    ManualWidgetActivity::class.java,
                    null
                )
                setOnClickPendingIntent(R.id.widget_4x2_action_manual, manualIntent)

                // Whole Card Click (Deep Link: kharcha://home)
                val cardIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("kharcha://home")
                )
                setOnClickPendingIntent(R.id.widget_4x2_container, cardIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
