package com.kharcha.kharcha

import android.app.DatePickerDialog
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.animation.AnimationUtils
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import android.app.Activity
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

import android.view.WindowManager
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import kotlin.math.max

class ManualWidgetActivity : Activity() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var layoutBottomSheet: View
    private lateinit var etAmount: EditText
    private lateinit var etMerchant: EditText
    private lateinit var tvCurrencyPrefix: TextView
    private lateinit var tvDate: TextView

    private var selectedCategory = "Food & Dining"
    private var selectedPaymentMethod = "Cash"
    private val selectedCalendar = Calendar.getInstance()
    private var currencySymbol = "Rs."

    private val categoryChips = mutableListOf<Pair<TextView, String>>()
    private val paymentChips = mutableListOf<Pair<TextView, String>>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        setContentView(R.layout.dialog_manual_bottom_sheet)

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        currencySymbol = readCurrencySymbol(prefs)

        layoutBottomSheet = findViewById(R.id.layout_manual_bottom_sheet)
        etAmount = findViewById(R.id.et_manual_amount)
        etMerchant = findViewById(R.id.et_manual_merchant)
        tvCurrencyPrefix = findViewById(R.id.tv_currency_prefix)
        tvDate = findViewById(R.id.tv_manual_date)

        tvCurrencyPrefix.text = currencySymbol

        val rootView = findViewById<View>(R.id.root_manual_view)
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { v, insets ->
            val imeInsets = insets.getInsets(WindowInsetsCompat.Type.ime())
            val navInsets = insets.getInsets(WindowInsetsCompat.Type.navigationBars())
            val bottomPadding = max(imeInsets.bottom, navInsets.bottom)
            v.setPadding(0, 0, 0, bottomPadding)
            insets
        }

        // Slide up entry animation
        val slideUp = AnimationUtils.loadAnimation(this, R.anim.slide_up_bottom)
        layoutBottomSheet.startAnimation(slideUp)

        setupDismiss()
        setupPresets()
        setupCategories()
        setupPaymentMethods()
        setupDatePicker()

        findViewById<View>(R.id.btn_manual_add).setOnClickListener {
            saveExpense()
        }

        findViewById<View>(R.id.btn_manual_cancel).setOnClickListener {
            dismissWithAnimation()
        }

        findViewById<View>(R.id.btn_manual_close).setOnClickListener {
            dismissWithAnimation()
        }

        // Show keyboard for amount after slide animation
        handler.postDelayed({
            etAmount.requestFocus()
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            imm?.showSoftInput(etAmount, InputMethodManager.SHOW_IMPLICIT)
        }, 220)
    }

    private fun setupDismiss() {
        findViewById<View>(R.id.root_manual_view).setOnClickListener {
            dismissWithAnimation()
        }
    }

    private fun setupPresets() {
        fun addPreset(delta: Double) {
            val current = etAmount.text.toString().toDoubleOrNull() ?: 0.0
            val next = current + delta
            val formatted = if (next % 1.0 == 0.0) next.toLong().toString() else next.toString()
            etAmount.setText(formatted)
            etAmount.setSelection(etAmount.text.length)
        }

        findViewById<View>(R.id.btn_preset_100).setOnClickListener { addPreset(100.0) }
        findViewById<View>(R.id.btn_preset_500).setOnClickListener { addPreset(500.0) }
        findViewById<View>(R.id.btn_preset_1000).setOnClickListener { addPreset(1000.0) }
        findViewById<View>(R.id.btn_preset_5000).setOnClickListener { addPreset(5000.0) }
        findViewById<View>(R.id.btn_preset_clear).setOnClickListener { etAmount.setText("") }
    }

    private fun setupCategories() {
        categoryChips.clear()
        categoryChips.add(Pair(findViewById(R.id.chip_cat_food), "Food & Dining"))
        categoryChips.add(Pair(findViewById(R.id.chip_cat_transport), "Transportation"))
        categoryChips.add(Pair(findViewById(R.id.chip_cat_groceries), "Groceries"))
        categoryChips.add(Pair(findViewById(R.id.chip_cat_shopping), "Shopping"))
        categoryChips.add(Pair(findViewById(R.id.chip_cat_bills), "Bills & Utilities"))
        categoryChips.add(Pair(findViewById(R.id.chip_cat_health), "Health"))
        categoryChips.add(Pair(findViewById(R.id.chip_cat_entertainment), "Entertainment"))
        categoryChips.add(Pair(findViewById(R.id.chip_cat_general), "General"))

        for ((chip, catName) in categoryChips) {
            chip.setOnClickListener {
                selectedCategory = catName
                updateCategoryChips()
            }
        }
        updateCategoryChips()
    }

    private fun updateCategoryChips() {
        val selectedColor = ContextCompat.getColor(this, R.color.popup_chip_selected_text)
        val unselectedColor = ContextCompat.getColor(this, R.color.popup_chip_unselected_text)
        for ((chip, catName) in categoryChips) {
            val isSelected = (catName == selectedCategory)
            chip.setBackgroundResource(if (isSelected) R.drawable.chip_selected_bg else R.drawable.chip_unselected_bg)
            chip.setTextColor(if (isSelected) selectedColor else unselectedColor)
            chip.setTypeface(null, if (isSelected) Typeface.BOLD else Typeface.NORMAL)
        }
    }

    private fun setupPaymentMethods() {
        paymentChips.clear()
        paymentChips.add(Pair(findViewById(R.id.chip_pay_cash), "Cash"))
        paymentChips.add(Pair(findViewById(R.id.chip_pay_card), "Card"))
        paymentChips.add(Pair(findViewById(R.id.chip_pay_easypaisa), "EasyPaisa"))

        for ((chip, method) in paymentChips) {
            chip.setOnClickListener {
                selectedPaymentMethod = method
                updatePaymentChips()
            }
        }
        updatePaymentChips()
    }

    private fun updatePaymentChips() {
        val selectedColor = ContextCompat.getColor(this, R.color.popup_chip_selected_text)
        val unselectedColor = ContextCompat.getColor(this, R.color.popup_chip_unselected_text)
        for ((chip, method) in paymentChips) {
            val isSelected = (method == selectedPaymentMethod)
            chip.setBackgroundResource(if (isSelected) R.drawable.chip_selected_bg else R.drawable.chip_unselected_bg)
            chip.setTextColor(if (isSelected) selectedColor else unselectedColor)
            chip.setTypeface(null, if (isSelected) Typeface.BOLD else Typeface.NORMAL)
        }
    }

    private fun setupDatePicker() {
        val dateFormat = SimpleDateFormat("MMM d", Locale.getDefault())
        tvDate.setOnClickListener {
            val dpd = DatePickerDialog(
                this,
                R.style.ModernDatePickerDialogTheme,
                { _, year, month, dayOfMonth ->
                    selectedCalendar.set(Calendar.YEAR, year)
                    selectedCalendar.set(Calendar.MONTH, month)
                    selectedCalendar.set(Calendar.DAY_OF_MONTH, dayOfMonth)

                    val todayCal = Calendar.getInstance()
                    if (todayCal.get(Calendar.YEAR) == year &&
                        todayCal.get(Calendar.DAY_OF_YEAR) == selectedCalendar.get(Calendar.DAY_OF_YEAR)
                    ) {
                        tvDate.text = "Today"
                    } else {
                        tvDate.text = dateFormat.format(selectedCalendar.time)
                    }
                },
                selectedCalendar.get(Calendar.YEAR),
                selectedCalendar.get(Calendar.MONTH),
                selectedCalendar.get(Calendar.DAY_OF_MONTH)
            )
            dpd.show()
        }
    }

    private fun saveExpense() {
        val amountStr = etAmount.text.toString().trim()
        val amount = amountStr.toDoubleOrNull() ?: 0.0

        if (amount <= 0.0) {
            Toast.makeText(this, "Please enter a valid amount", Toast.LENGTH_SHORT).show()
            etAmount.requestFocus()
            return
        }

        val merchantRaw = etMerchant.text.toString().trim()
        val merchant = if (merchantRaw.isNotEmpty()) merchantRaw else selectedCategory

        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val TRANSACTIONS_KEY = "flutter.kharcha.transactions.v1"
            val rawTx = prefs.getString(TRANSACTIONS_KEY, null)
            val txArray = if (!rawTx.isNullOrEmpty()) JSONArray(rawTx) else JSONArray()

            val isoFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).apply {
                timeZone = TimeZone.getDefault()
            }

            val newTx = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("merchant", merchant)
                put("amount", amount)
                put("category", selectedCategory)
                put("date", isoFormat.format(selectedCalendar.time))
                put("isIncome", false)
                put("source", "manual")
                put("paymentMethod", selectedPaymentMethod)
                put("createdAt", isoFormat.format(Calendar.getInstance().time))
            }

            val newArray = JSONArray().apply { put(newTx) }
            for (i in 0 until txArray.length()) {
                newArray.put(txArray.getJSONObject(i))
            }

            prefs.edit().putString(TRANSACTIONS_KEY, newArray.toString()).apply()

            // Update widgets synchronously
            updateAllWidgets(this)

            // Broadcast to MainActivity to sync in-memory Flutter repositories
            try {
                val syncIntent = Intent("com.kharcha.kharcha.TRANSACTION_ADDED").apply {
                    setPackage(packageName)
                }
                sendBroadcast(syncIntent)
            } catch (e: Exception) {}

            val formatter = NumberFormat.getNumberInstance(Locale.US)
            val savedAmountStr = formatter.format(amount.toLong())
            Toast.makeText(this, "✓ Added $currencySymbol $savedAmountStr for $merchant", Toast.LENGTH_SHORT).show()

            dismissWithAnimation()
        } catch (e: Exception) {
            Toast.makeText(this, "Error saving: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun updateAllWidgets(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            // 1. Update 4x1 Widget
            val widget4x1 = ComponentName(context, KharchaWidgetProvider::class.java)
            val ids4x1 = appWidgetManager.getAppWidgetIds(widget4x1)
            if (ids4x1.isNotEmpty()) {
                KharchaWidgetProvider().onUpdate(context, appWidgetManager, ids4x1, prefs)
            }

            // 2. Update 2x2 Widget
            val widget2x2 = ComponentName(context, KharchaWidget2x2Provider::class.java)
            val ids2x2 = appWidgetManager.getAppWidgetIds(widget2x2)
            if (ids2x2.isNotEmpty()) {
                KharchaWidget2x2Provider().onUpdate(context, appWidgetManager, ids2x2, prefs)
            }

            // 3. Update 4x2 Widget
            val widget4x2 = ComponentName(context, KharchaWidget4x2Provider::class.java)
            val ids4x2 = appWidgetManager.getAppWidgetIds(widget4x2)
            if (ids4x2.isNotEmpty()) {
                KharchaWidget4x2Provider().onUpdate(context, appWidgetManager, ids4x2, prefs)
            }
        } catch (e: Exception) {}
    }

    private fun dismissWithAnimation() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.hideSoftInputFromWindow(etAmount.windowToken, 0)

        val slideDown = AnimationUtils.loadAnimation(this, R.anim.slide_down_bottom)
        layoutBottomSheet.startAnimation(slideDown)
        handler.postDelayed({
            finish()
            overridePendingTransition(0, 0)
        }, 180)
    }

    private fun readCurrencySymbol(prefs: android.content.SharedPreferences): String {
        val settingsRaw = prefs.getString("flutter.kharcha.settings.v1", null)
        if (!settingsRaw.isNullOrEmpty()) {
            try {
                val json = JSONObject(settingsRaw)
                val symbol = json.optString("currencySymbol", "")
                if (symbol.isNotBlank()) return symbol
            } catch (e: Exception) {}
        }
        return "Rs."
    }
}
