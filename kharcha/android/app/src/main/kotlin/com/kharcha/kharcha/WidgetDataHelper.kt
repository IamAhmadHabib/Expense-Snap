package com.kharcha.kharcha

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

data class WidgetMetrics(
    val todayAmount: String,
    val todayCount: String,
    val currency: String,
    val monthlyBudget: Double,
    val monthSpent: Double,
    val remainingBudget: Double,
    val remainingBudgetFormatted: String,
    val budgetPercent: Float,
    val budgetProgressInt: Int,
    val thisWeekTotals: DoubleArray,
    val todayDayIndex: Int
)

object WidgetDataHelper {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val TRANSACTIONS_KEY = "flutter.kharcha.transactions.v1"
    private const val SETTINGS_KEY = "flutter.kharcha.settings.v1"

    fun calculateMetrics(context: Context): WidgetMetrics {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // 1. Read Currency Symbol & Monthly Budget
        var currency = "Rs."
        var monthlyBudget = 0.0
        val settingsRaw = prefs.getString(SETTINGS_KEY, null)
        if (!settingsRaw.isNullOrEmpty()) {
            try {
                val json = JSONObject(settingsRaw)
                val symbol = json.optString("currencySymbol", "")
                if (symbol.isNotBlank()) currency = symbol
                monthlyBudget = json.optDouble("monthlyBudget", 0.0)
            } catch (e: Exception) {}
        }

        // 2. Read Transactions & Time Calculations
        val rawTx = prefs.getString(TRANSACTIONS_KEY, null)
        var todayTotal = 0.0
        var todayCount = 0
        var monthTotal = 0.0

        val calToday = Calendar.getInstance()
        val todayYear = calToday.get(Calendar.YEAR)
        val todayMonth = calToday.get(Calendar.MONTH)
        val todayDay = calToday.get(Calendar.DAY_OF_MONTH)

        // Current week (Monday=0 to Sunday=6)
        val currentDayOfWeek = calToday.get(Calendar.DAY_OF_WEEK) // Sunday=1, Monday=2, ..., Saturday=7
        val daysFromMonday = if (currentDayOfWeek == Calendar.SUNDAY) 6 else currentDayOfWeek - Calendar.MONDAY
        val todayDayIndex = daysFromMonday.coerceIn(0, 6)

        val calMonday = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -daysFromMonday)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val calSundayEnd = Calendar.getInstance().apply {
            timeInMillis = calMonday.timeInMillis
            add(Calendar.DAY_OF_YEAR, 7)
        }

        val thisWeekTotals = DoubleArray(7) { 0.0 }

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
                                val amount = item.optDouble("amount", 0.0)

                                // Current month total
                                if (calTx.get(Calendar.YEAR) == todayYear &&
                                    calTx.get(Calendar.MONTH) == todayMonth
                                ) {
                                    monthTotal += amount
                                }

                                // Today's total and count
                                if (calTx.get(Calendar.YEAR) == todayYear &&
                                    calTx.get(Calendar.MONTH) == todayMonth &&
                                    calTx.get(Calendar.DAY_OF_MONTH) == todayDay
                                ) {
                                    todayTotal += amount
                                    todayCount++
                                }

                                // This week's breakdown (Monday to Sunday)
                                if (calTx.timeInMillis >= calMonday.timeInMillis &&
                                    calTx.timeInMillis < calSundayEnd.timeInMillis
                                ) {
                                    val diffMs = calTx.timeInMillis - calMonday.timeInMillis
                                    val dayIdx = (diffMs / (1000 * 60 * 60 * 24)).toInt().coerceIn(0, 6)
                                    thisWeekTotals[dayIdx] += amount
                                }
                            }
                        } catch (e: Exception) {}
                    }
                }
            } catch (e: Exception) {}
        }

        val formatter = NumberFormat.getNumberInstance(Locale.US)
        val formattedTodayAmount = "$currency ${formatter.format(todayTotal.toLong())}"
        val countText = if (todayCount == 1) "1 expense today" else "$todayCount expenses today"

        val remainingBudget = (monthlyBudget - monthTotal).coerceAtLeast(0.0)
        val remainingBudgetFormatted = if (monthlyBudget > 0) {
            "$currency ${formatter.format(remainingBudget.toLong())} left"
        } else {
            "Budget not set"
        }

        val budgetPercent = if (monthlyBudget > 0) {
            ((monthTotal / monthlyBudget) * 100.0).toFloat().coerceIn(0f, 100f)
        } else {
            0f
        }

        // Cache snapshot
        prefs.edit()
            .putString("today_spent", formattedTodayAmount)
            .putString("today_count", countText)
            .putString("currency", currency)
            .putFloat("widget_budget_percent", budgetPercent)
            .putString("widget_remaining_budget", remainingBudgetFormatted)
            .apply()

        return WidgetMetrics(
            todayAmount = formattedTodayAmount,
            todayCount = countText,
            currency = currency,
            monthlyBudget = monthlyBudget,
            monthSpent = monthTotal,
            remainingBudget = remainingBudget,
            remainingBudgetFormatted = remainingBudgetFormatted,
            budgetPercent = budgetPercent,
            budgetProgressInt = budgetPercent.toInt(),
            thisWeekTotals = thisWeekTotals,
            todayDayIndex = todayDayIndex
        )
    }

    fun drawBudgetRing(context: Context, percent: Float, sizeDp: Int = 82): Bitmap {
        val density = context.resources.displayMetrics.density
        val sizePx = (sizeDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val strokeWidth = 7f * density
        val padding = strokeWidth / 2f + 2.5f * density
        val rect = RectF(padding, padding, sizePx - padding, sizePx - padding)

        // Background Track
        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            this.strokeWidth = strokeWidth
            color = Color.parseColor("#EAE6DF") // Soft warm cream track
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawArc(rect, 0f, 360f, false, trackPaint)

        // Progress Arc
        if (percent > 0f) {
            val progressPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
                color = Color.parseColor("#E5A33C") // Amber gold
                strokeCap = Paint.Cap.ROUND
            }
            val sweepAngle = (percent.coerceIn(0f, 100f) / 100f) * 360f
            canvas.drawArc(rect, -90f, sweepAngle, false, progressPaint)
        }

        return bitmap
    }

    fun drawThisWeekChart(
        context: Context,
        weeklyTotals: DoubleArray,
        todayIndex: Int,
        widthDp: Int = 150,
        heightDp: Int = 54
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val widthPx = (widthDp * density).toInt().coerceAtLeast(1)
        val heightPx = (heightDp * density).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val barCount = 7
        val barWidth = 10f * density
        val totalBarsWidth = barCount * barWidth
        val gap = (widthPx - totalBarsWidth) / 6f

        val trackTop = 2f * density
        val trackBottom = heightPx - (16f * density)
        val trackHeight = trackBottom - trackTop
        val cornerRadius = barWidth / 2f

        val maxVal = (weeklyTotals.maxOrNull() ?: 0.0).coerceAtLeast(1.0)
        val dayLabels = arrayOf("M", "T", "W", "T", "F", "S", "S")

        val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#EDE8E1") // Subtle warm neutral track
            style = Paint.Style.FILL
        }

        val pastBarPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#1C1C1E") // Obsidian charcoal for past days
            style = Paint.Style.FILL
        }

        val todayBarPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#E5A33C") // Amber gold for today
            style = Paint.Style.FILL
        }

        val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#D1CAC1")
            style = Paint.Style.FILL
        }

        val todayDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#E5A33C")
            style = Paint.Style.FILL
        }

        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
        }

        for (i in 0 until barCount) {
            val left = i * (barWidth + gap)
            val right = left + barWidth
            val centerX = left + (barWidth / 2f)

            // 1. Draw Full Pill Track
            val trackRect = RectF(left, trackTop, right, trackBottom)
            canvas.drawRoundRect(trackRect, cornerRadius, cornerRadius, trackPaint)

            // 2. Draw Filled Bar or Baseline Dot
            if (i <= todayIndex) {
                val amount = weeklyTotals[i]
                if (amount > 0) {
                    val ratio = (amount / maxVal).coerceIn(0.0, 1.0)
                    val fillHeight = (ratio * (trackHeight - 4f * density)).toFloat().coerceAtLeast(6f * density)
                    val fillTop = trackBottom - fillHeight
                    val fillRect = RectF(left, fillTop, right, trackBottom)
                    val paint = if (i == todayIndex) todayBarPaint else pastBarPaint
                    canvas.drawRoundRect(fillRect, cornerRadius, cornerRadius, paint)
                } else {
                    // Zero expense day: draw a tidy baseline dot
                    val dotRadius = 2.2f * density
                    val dotCenterY = trackBottom - cornerRadius
                    val paint = if (i == todayIndex) todayDotPaint else dotPaint
                    canvas.drawCircle(centerX, dotCenterY, dotRadius, paint)
                }
            }

            // 3. Draw Day of Week Label (M, T, W, T, F, S, S)
            val label = dayLabels[i]
            if (i == todayIndex) {
                textPaint.color = Color.parseColor("#E5A33C")
                textPaint.typeface = Typeface.DEFAULT_BOLD
                textPaint.textSize = 10f * density
            } else if (i < todayIndex) {
                textPaint.color = Color.parseColor("#8C7E6E")
                textPaint.typeface = Typeface.DEFAULT_BOLD
                textPaint.textSize = 9.5f * density
            } else {
                // Future day
                textPaint.color = Color.parseColor("#C4B8A8")
                textPaint.typeface = Typeface.DEFAULT
                textPaint.textSize = 9f * density
            }

            val labelY = heightPx - (2f * density)
            canvas.drawText(label, centerX, labelY, textPaint)
        }

        return bitmap
    }
}
