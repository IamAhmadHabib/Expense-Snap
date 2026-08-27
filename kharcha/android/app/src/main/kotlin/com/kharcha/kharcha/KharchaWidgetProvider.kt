package com.kharcha.kharcha

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

class KharchaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kharcha_widget_layout).apply {
                val todayAmount = widgetData.getString("today_spent", "Rs 0") ?: "Rs 0"
                val todayCount = widgetData.getString("today_count", "0 expenses today") ?: "0 expenses today"
                val currency = widgetData.getString("currency", "PKR") ?: "PKR"

                setTextViewText(R.id.widget_today_amount, todayAmount)
                setTextViewText(R.id.widget_today_count, todayCount)
                setTextViewText(R.id.widget_currency_tag, currency)

                // Voice Action -> Native VoiceWidgetActivity (keeps the app closed!)
                val voiceIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    VoiceWidgetActivity::class.java,
                    null
                )
                setOnClickPendingIntent(R.id.widget_action_voice, voiceIntent)

                // Scan Action (Deep Link: kharcha://capture/scan)
                val scanIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("kharcha://capture/scan")
                )
                setOnClickPendingIntent(R.id.widget_action_scan, scanIntent)

                // Manual Action (Deep Link: kharcha://capture/manual)
                val manualIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("kharcha://capture/manual")
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