package com.kharcha.kharcha

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.animation.AnimationUtils
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
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

class ScanWidgetActivity : ComponentActivity() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var layoutBottomSheet: View
    private lateinit var etAmount: EditText
    private lateinit var etMerchant: EditText
    private lateinit var tvCurrencyPrefix: TextView
    private lateinit var ivThumbnail: ImageView
    private lateinit var tvOcrStatus: TextView

    private var selectedCategory = "Groceries"
    private var currencySymbol = "Rs."
    private var capturedBitmap: Bitmap? = null

    private val categoryChips = mutableListOf<Pair<TextView, String>>()

    private val takePictureLauncher = registerForActivityResult(ActivityResultContracts.TakePicturePreview()) { bitmap ->
        if (bitmap != null) {
            capturedBitmap = bitmap
            ivThumbnail.setImageBitmap(bitmap)
            processReceiptBitmap(bitmap)
        } else {
            // User cancelled camera; show review sheet so they can retake or type
            tvOcrStatus.text = "Camera cancelled"
        }
    }

    private val requestPermissionLauncher = registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
        if (isGranted) {
            launchCamera()
        } else {
            Toast.makeText(this, "Camera permission needed to scan receipts", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        setContentView(R.layout.dialog_scan_bottom_sheet)

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        currencySymbol = readCurrencySymbol(prefs)

        layoutBottomSheet = findViewById(R.id.layout_scan_bottom_sheet)
        etAmount = findViewById(R.id.et_scan_amount)
        etMerchant = findViewById(R.id.et_scan_merchant)
        tvCurrencyPrefix = findViewById(R.id.tv_scan_currency_prefix)
        ivThumbnail = findViewById(R.id.iv_receipt_thumbnail)
        tvOcrStatus = findViewById(R.id.tv_ocr_status)

        tvCurrencyPrefix.text = currencySymbol

        val rootView = findViewById<View>(R.id.root_scan_view)
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { v, insets ->
            val imeInsets = insets.getInsets(WindowInsetsCompat.Type.ime())
            val navInsets = insets.getInsets(WindowInsetsCompat.Type.navigationBars())
            val bottomPadding = max(imeInsets.bottom, navInsets.bottom)
            v.setPadding(0, 0, 0, bottomPadding)
            insets
        }

        val slideUp = AnimationUtils.loadAnimation(this, R.anim.slide_up_bottom)
        layoutBottomSheet.startAnimation(slideUp)

        setupDismiss()
        setupCategories()

        findViewById<View>(R.id.btn_scan_add).setOnClickListener {
            saveExpense()
        }

        findViewById<View>(R.id.btn_scan_retake).setOnClickListener {
            launchCamera()
        }

        findViewById<View>(R.id.btn_scan_close).setOnClickListener {
            dismissWithAnimation()
        }

        // Check camera permission and launch camera immediately
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            launchCamera()
        } else {
            requestPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun launchCamera() {
        try {
            takePictureLauncher.launch(null)
        } catch (e: Exception) {
            Toast.makeText(this, "Camera error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun processReceiptBitmap(bitmap: Bitmap) {
        tvOcrStatus.text = "Analyzing receipt with AI..."
        try {
            val image = InputImage.fromBitmap(bitmap, 0)
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    val parsed = ReceiptOcrParser.parse(visionText.text)
                    val formatted = if (parsed.amount > 0.0) {
                        if (parsed.amount % 1.0 == 0.0) parsed.amount.toLong().toString() else parsed.amount.toString()
                    } else {
                        ""
                    }
                    etAmount.setText(formatted)
                    etMerchant.setText(parsed.merchant)
                    selectedCategory = parsed.category
                    updateCategoryChips()
                    tvOcrStatus.text = if (parsed.amount > 0.0) "✓ Bill Total Extracted" else "✓ Receipt Scanned"
                }
                .addOnFailureListener { e ->
                    tvOcrStatus.text = "Review details below"
                }
        } catch (e: Exception) {
            tvOcrStatus.text = "Review details below"
        }
    }

    private fun setupDismiss() {
        findViewById<View>(R.id.root_scan_view).setOnClickListener {
            dismissWithAnimation()
        }
    }

    private fun setupCategories() {
        categoryChips.clear()
        categoryChips.add(Pair(findViewById(R.id.chip_scan_food), "Food & Dining"))
        categoryChips.add(Pair(findViewById(R.id.chip_scan_groceries), "Groceries"))
        categoryChips.add(Pair(findViewById(R.id.chip_scan_shopping), "Shopping"))
        categoryChips.add(Pair(findViewById(R.id.chip_scan_transport), "Transportation"))
        categoryChips.add(Pair(findViewById(R.id.chip_scan_bills), "Bills & Utilities"))
        categoryChips.add(Pair(findViewById(R.id.chip_scan_health), "Health"))
        categoryChips.add(Pair(findViewById(R.id.chip_scan_entertainment), "Entertainment"))
        categoryChips.add(Pair(findViewById(R.id.chip_scan_general), "General"))

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

    private fun saveExpense() {
        val amountStr = etAmount.text.toString().trim()
        val amount = amountStr.toDoubleOrNull() ?: 0.0

        if (amount <= 0.0) {
            Toast.makeText(this, "Please enter a valid amount", Toast.LENGTH_SHORT).show()
            etAmount.requestFocus()
            return
        }

        val merchantRaw = etMerchant.text.toString().trim()
        val merchant = if (merchantRaw.isNotEmpty()) merchantRaw else "Scanned Receipt"

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
                put("date", isoFormat.format(Calendar.getInstance().time))
                put("isIncome", false)
                put("source", "scan")
                put("paymentMethod", "Cash")
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
            Toast.makeText(this, "✓ Added $currencySymbol $savedAmountStr from receipt", Toast.LENGTH_SHORT).show()

            dismissWithAnimation()
        } catch (e: Exception) {
            Toast.makeText(this, "Error saving: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun updateAllWidgets(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            val widget4x1 = ComponentName(context, KharchaWidgetProvider::class.java)
            val ids4x1 = appWidgetManager.getAppWidgetIds(widget4x1)
            if (ids4x1.isNotEmpty()) {
                KharchaWidgetProvider().onUpdate(context, appWidgetManager, ids4x1, prefs)
            }

            val widget2x2 = ComponentName(context, KharchaWidget2x2Provider::class.java)
            val ids2x2 = appWidgetManager.getAppWidgetIds(widget2x2)
            if (ids2x2.isNotEmpty()) {
                KharchaWidget2x2Provider().onUpdate(context, appWidgetManager, ids2x2, prefs)
            }

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
