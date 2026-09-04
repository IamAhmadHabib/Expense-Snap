package com.kharcha.kharcha

import android.Manifest
import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.view.View
import android.view.animation.AnimationUtils
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONArray
import org.json.JSONObject
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.max
import kotlin.math.min

import android.view.WindowManager
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class VoiceWidgetActivity : Activity() {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 2001
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val TRANSACTIONS_KEY = "flutter.kharcha.transactions.v1"
        private const val SETTINGS_KEY = "flutter.kharcha.settings.v1"
    }

    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var capturedTranscript: String = ""
    private var parsedTransaction: ParsedVoiceExpense? = null

    // UI elements
    private lateinit var layoutBottomSheet: LinearLayout
    private lateinit var layoutListeningView: LinearLayout
    private lateinit var layoutReviewView: LinearLayout
    private lateinit var layoutFallbackView: LinearLayout
    private lateinit var tvStatusSubtitle: TextView
    private lateinit var tvTranscript: TextView
    private lateinit var etAmount: EditText
    private lateinit var etMerchant: EditText
    private lateinit var tvCategoryBadge: TextView
    private lateinit var tvCurrencySymbol: TextView
    private lateinit var btnCancel: TextView
    private lateinit var btnAddExpense: TextView
    private lateinit var btnFallbackTryAgain: TextView
    private lateinit var btnFallbackManual: TextView
    private lateinit var rippleVoiceIndicator: View
    private lateinit var ivMicIcon: ImageView

    private var selectedCategory: String = "Food & Dining"
    private var currencySymbol: String = "Rs."

    // Waveform bars
    private lateinit var waveBar1: View
    private lateinit var waveBar2: View
    private lateinit var waveBar3: View
    private lateinit var waveBar4: View
    private lateinit var waveBar5: View

    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        setFinishOnTouchOutside(false)
        setContentView(R.layout.dialog_voice_bottom_sheet)

        val rootView = findViewById<View>(R.id.root_container)
        ViewCompat.setOnApplyWindowInsetsListener(rootView) { v, insets ->
            val imeInsets = insets.getInsets(WindowInsetsCompat.Type.ime())
            val navInsets = insets.getInsets(WindowInsetsCompat.Type.navigationBars())
            val bottomPadding = max(imeInsets.bottom, navInsets.bottom)
            v.setPadding(0, 0, 0, bottomPadding)
            insets
        }

        bindViews()
        setupListeners()
        setupCurrency()

        // Slide in bottom sheet with hardware-accelerated animation
        val slideUp = AnimationUtils.loadAnimation(this, R.anim.slide_up_bottom)
        layoutBottomSheet.startAnimation(slideUp)

        // Check audio recording permissions
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            == PackageManager.PERMISSION_GRANTED
        ) {
            startSpeechListening()
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    private fun bindViews() {
        layoutBottomSheet = findViewById(R.id.layout_bottom_sheet)
        layoutListeningView = findViewById(R.id.layout_listening_view)
        layoutReviewView = findViewById(R.id.layout_review_view)
        layoutFallbackView = findViewById(R.id.layout_fallback_view)

        tvStatusSubtitle = findViewById(R.id.tv_status_subtitle)
        tvTranscript = findViewById(R.id.tv_transcript)
        etAmount = findViewById(R.id.et_amount)
        etMerchant = findViewById(R.id.et_merchant)
        tvCategoryBadge = findViewById(R.id.tv_category_badge)
        tvCurrencySymbol = findViewById(R.id.tv_currency_symbol)

        waveBar1 = findViewById(R.id.wave_bar_1)
        waveBar2 = findViewById(R.id.wave_bar_2)
        waveBar3 = findViewById(R.id.wave_bar_3)
        waveBar4 = findViewById(R.id.wave_bar_4)
        waveBar5 = findViewById(R.id.wave_bar_5)
    }

    private fun setupListeners() {
        // Dismiss ONLY on tap outside scrim or close button
        findViewById<View>(R.id.view_outside_scrim).setOnClickListener {
            dismissWithAnimation()
        }
        findViewById<View>(R.id.btn_close).setOnClickListener {
            dismissWithAnimation()
        }

        // Strictly consume all touches on the bottom sheet so they NEVER dismiss
        layoutBottomSheet.setOnTouchListener { _, _ -> true }
        layoutReviewView.setOnTouchListener { _, _ -> true }
        layoutListeningView.setOnTouchListener { _, _ -> true }
        layoutFallbackView.setOnTouchListener { _, _ -> true }

        // Tapping the amount card focuses amount field
        findViewById<View>(R.id.card_amount).setOnClickListener {
            etAmount.requestFocus()
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager
            imm?.showSoftInput(etAmount, android.view.inputmethod.InputMethodManager.SHOW_IMPLICIT)
        }

        // Tapping the merchant card focuses merchant field
        findViewById<View>(R.id.card_merchant).setOnClickListener {
            etMerchant.requestFocus()
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? android.view.inputmethod.InputMethodManager
            imm?.showSoftInput(etMerchant, android.view.inputmethod.InputMethodManager.SHOW_IMPLICIT)
        }

        // Finish speaking early button
        findViewById<View>(R.id.btn_finish_speech).setOnClickListener {
            stopSpeechRecognizer()
        }

        // Retry button in Review view
        findViewById<View>(R.id.btn_retry).setOnClickListener {
            startSpeechListening()
        }

        // Retry in fallback view
        findViewById<View>(R.id.btn_fallback_retry).setOnClickListener {
            startSpeechListening()
        }

        // Open full app from fallback view
        findViewById<View>(R.id.btn_open_app).setOnClickListener {
            val intent = Intent(this, MainActivity::class.java).apply {
                data = Uri.parse("kharcha://capture/voice")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            startActivity(intent)
            dismissWithAnimation()
        }

        // Add Expense Confirm button
        findViewById<View>(R.id.btn_add_expense).setOnClickListener {
            saveAndFinish()
        }
    }

    private fun setupCurrency() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val symbol = readCurrencySymbol(prefs)
        tvCurrencySymbol.text = symbol
    }

    private fun startSpeechListening() {
        stopSpeechRecognizer()

        // Switch to listening state
        layoutListeningView.visibility = View.VISIBLE
        layoutReviewView.visibility = View.GONE
        layoutFallbackView.visibility = View.GONE
        tvStatusSubtitle.text = "Listening... Speak naturally"
        tvTranscript.text = "Say: 'Lunch 450' or 'Petrol 2 hazar'"
        tvTranscript.setTextColor(ContextCompat.getColor(this, R.color.popup_text_muted))
        capturedTranscript = ""

        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            showFallback("Voice recognition not available on this device")
            return
        }

        try {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
                setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {
                        isListening = true
                        tvStatusSubtitle.text = "Listening..."
                    }

                    override fun onBeginningOfSpeech() {
                        tvStatusSubtitle.text = "Listening to you..."
                    }

                    override fun onRmsChanged(rmsdB: Float) {
                        updateWaveform(rmsdB)
                    }

                    override fun onBufferReceived(buffer: ByteArray?) {}

                    override fun onEndOfSpeech() {
                        isListening = false
                        tvStatusSubtitle.text = "Processing expense..."
                        resetWaveform()
                    }

                    override fun onError(error: Int) {
                        isListening = false
                        resetWaveform()
                        if (capturedTranscript.isNotBlank()) {
                            onSpeechFinished(capturedTranscript)
                        } else {
                            val msg = when (error) {
                                SpeechRecognizer.ERROR_NO_MATCH,
                                SpeechRecognizer.ERROR_SPEECH_TIMEOUT ->
                                    "Didn't catch that. Tap Try Again or Speak clearly."
                                SpeechRecognizer.ERROR_AUDIO ->
                                    "Audio recording error. Please retry."
                                else ->
                                    "No voice recognized. Tap Try Again."
                            }
                            showFallback(msg)
                        }
                    }

                    override fun onResults(results: Bundle?) {
                        isListening = false
                        resetWaveform()
                        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = matches?.firstOrNull() ?: capturedTranscript
                        if (text.isNotBlank()) {
                            onSpeechFinished(text)
                        } else {
                            showFallback("Didn't catch that. Tap Try Again.")
                        }
                    }

                    override fun onPartialResults(partialResults: Bundle?) {
                        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val partial = matches?.firstOrNull() ?: ""
                        if (partial.isNotBlank()) {
                            capturedTranscript = partial
                            tvTranscript.text = partial
                            tvTranscript.setTextColor(ContextCompat.getColor(this@VoiceWidgetActivity, R.color.popup_text_primary))
                        }
                    }

                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })
            }

            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)

                // Generous pause tolerance (3.5 - 4.0 seconds of thinking silence before auto-terminating)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 4000L)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 3500L)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 3000L)
            }

            speechRecognizer?.startListening(intent)
        } catch (e: Exception) {
            showFallback("Failed to start voice listener: ${e.localizedMessage}")
        }
    }

    private fun stopSpeechRecognizer() {
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.destroy()
        } catch (e: Exception) {}
        speechRecognizer = null
        isListening = false
        resetWaveform()
    }

    private fun updateWaveform(rmsdB: Float) {
        // rmsdB typically ranges from -2 to 10
        val clamped = max(0f, min(12f, rmsdB + 2f))
        val factor = clamped / 12f

        val density = resources.displayMetrics.density
        val baseH = (12 * density).toInt()
        val maxAddH = (36 * density).toInt()

        handler.post {
            val h1 = baseH + (maxAddH * factor * 0.4f).toInt()
            val h2 = baseH + (maxAddH * factor * 0.75f).toInt()
            val h3 = baseH + (maxAddH * factor * 1.0f).toInt()
            val h4 = baseH + (maxAddH * factor * 0.7f).toInt()
            val h5 = baseH + (maxAddH * factor * 0.35f).toInt()

            waveBar1.layoutParams = waveBar1.layoutParams.apply { height = h1 }
            waveBar2.layoutParams = waveBar2.layoutParams.apply { height = h2 }
            waveBar3.layoutParams = waveBar3.layoutParams.apply { height = h3 }
            waveBar4.layoutParams = waveBar4.layoutParams.apply { height = h4 }
            waveBar5.layoutParams = waveBar5.layoutParams.apply { height = h5 }
        }
    }

    private fun resetWaveform() {
        val density = resources.displayMetrics.density
        val baseH = (12 * density).toInt()
        handler.post {
            waveBar1.layoutParams = waveBar1.layoutParams.apply { height = baseH }
            waveBar2.layoutParams = waveBar2.layoutParams.apply { height = (24 * density).toInt() }
            waveBar3.layoutParams = waveBar3.layoutParams.apply { height = (38 * density).toInt() }
            waveBar4.layoutParams = waveBar4.layoutParams.apply { height = (24 * density).toInt() }
            waveBar5.layoutParams = waveBar5.layoutParams.apply { height = baseH }
        }
    }

    private fun onSpeechFinished(text: String) {
        stopSpeechRecognizer()
        capturedTranscript = text

        val parsed = VoiceTransactionParser.parse(text)
        parsedTransaction = parsed

        // Populate review UI
        val formattedAmount = if (parsed.amount % 1.0 == 0.0) {
            parsed.amount.toLong().toString()
        } else {
            parsed.amount.toString()
        }

        etAmount.setText(formattedAmount)
        etMerchant.setText(if (parsed.merchant.isNotBlank()) parsed.merchant else parsed.rawText)
        tvCategoryBadge.text = parsed.category

        tvStatusSubtitle.text = "Review & Confirm"

        layoutListeningView.visibility = View.GONE
        layoutReviewView.visibility = View.VISIBLE
        layoutFallbackView.visibility = View.GONE
    }

    private fun showFallback(message: String) {
        tvStatusSubtitle.text = "Voice Input"
        findViewById<TextView>(R.id.tv_fallback_msg).text = message

        layoutListeningView.visibility = View.GONE
        layoutReviewView.visibility = View.GONE
        layoutFallbackView.visibility = View.VISIBLE
    }

    private fun saveAndFinish() {
        try {
            val amountText = etAmount.text.toString().trim()
            val amount = amountText.toDoubleOrNull() ?: parsedTransaction?.amount ?: 0.0
            val defaultMerchant = parsedTransaction?.merchant?.takeIf { it.isNotBlank() } ?: "Voice Expense"
            val merchant = etMerchant.text.toString().trim().ifBlank { defaultMerchant }
            val category = parsedTransaction?.category ?: "Food & Dining"
            val rawNote = capturedTranscript.ifBlank { merchant }
            val isIncome = parsedTransaction?.isIncome ?: false

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

            val txJson = JSONObject().apply {
                put("id", txId)
                put("remoteId", JSONObject.NULL)
                put("merchant", merchant)
                put("category", category)
                put("amount", amount)
                put("date", dateStr)
                put("note", rawNote)
                put("method", "Cash")
                put("source", "voice")
                put("isIncome", isIncome)
                put("syncState", "pendingCreate")
                put("syncFailure", JSONObject.NULL)
                put("attachmentIds", JSONArray())
                put("lastSyncedAt", JSONObject.NULL)
                put("updatedAt", utcStr)
                put("deletedAt", JSONObject.NULL)
            }

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

            val newArray = JSONArray()
            newArray.put(txJson)
            for (i in 0 until transactionsArray.length()) {
                newArray.put(transactionsArray.getJSONObject(i))
            }

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
                val itemIsIncome = item.optBoolean("isIncome", false)
                val itemDateStr = item.optString("date", "")
                if (!itemIsIncome && itemDateStr.isNotEmpty()) {
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
                    } catch (e: Exception) {}
                }
            }

            val formatter = NumberFormat.getNumberInstance(Locale.US)
            val formattedAmount = "$currency ${formatter.format(todayTotal.toLong())}"
            val countText = if (todayCount == 1) "1 expense today" else "$todayCount expenses today"

            prefs.edit()
                .putString("today_spent", formattedAmount)
                .putString("today_count", countText)
                .putString("currency", currency)
                .apply()

            updateHomeScreenWidget(this)

            // Broadcast to MainActivity to sync in-memory Flutter repositories immediately
            try {
                val syncIntent = Intent("com.kharcha.kharcha.TRANSACTION_ADDED").apply {
                    setPackage(packageName)
                }
                sendBroadcast(syncIntent)
            } catch (e: Exception) {}

            val savedAmountStr = formatter.format(amount.toLong())
            Toast.makeText(this, "✓ Added $currency $savedAmountStr for $merchant", Toast.LENGTH_SHORT).show()

            dismissWithAnimation()
        } catch (e: Exception) {
            Toast.makeText(this, "Error saving: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun dismissWithAnimation() {
        stopSpeechRecognizer()
        val slideDown = AnimationUtils.loadAnimation(this, R.anim.slide_down_bottom)
        layoutBottomSheet.startAnimation(slideDown)
        handler.postDelayed({
            finish()
            overridePendingTransition(0, 0)
        }, 180)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startSpeechListening()
            } else {
                showFallback("Microphone permission required for voice expense logging")
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopSpeechRecognizer()
    }

    private fun readCurrencySymbol(prefs: SharedPreferences): String {
        val settingsRaw = prefs.getString(SETTINGS_KEY, null)
        if (!settingsRaw.isNullOrEmpty()) {
            try {
                val json = JSONObject(settingsRaw)
                val symbol = json.optString("currencySymbol", "")
                if (symbol.isNotBlank()) return symbol
            } catch (e: Exception) {}
        }
        return "Rs."
    }

    private fun updateHomeScreenWidget(context: Context) {
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
}
