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

class KharchaWidget2x2Provider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_CONFIGURATION_CHANGED
        ) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, KharchaWidget2x2Provider::class.java)
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
        val ringBitmap = WidgetDataHelper.drawBudgetRing(context, metrics.budgetPercent, 82)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.kharcha_widget_2x2_layout).apply {
                setTextViewText(R.id.widget_2x2_today_amount, metrics.todayAmount)
                setTextViewText(R.id.widget_2x2_remaining_budget, metrics.remainingBudgetFormatted)
                setTextViewText(R.id.widget_2x2_currency_tag, metrics.currency)
                setImageViewBitmap(R.id.widget_2x2_budget_ring, ringBitmap)

                // Whole Card Click -> Open Kharcha App
                val cardIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("kharcha://home")
                )
                setOnClickPendingIntent(R.id.widget_2x2_container, cardIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
