package com.kharcha.kharcha

import java.util.regex.Pattern

data class ParsedReceipt(
    val amount: Double,
    val merchant: String,
    val category: String,
    val rawText: String
)

object ReceiptOcrParser {

    private val amountRegex = Pattern.compile("(?:total|grand\\s*total|net|amount|bill|rs\\.?|pkr)?\\s*[:=]?\\s*([0-9]{1,3}(?:[,.][0-9]{3})*(?:\\.[0-9]{1,2})?|[0-9]+)", Pattern.CASE_INSENSITIVE)

    fun parse(ocrText: String): ParsedReceipt {
        if (ocrText.isBlank()) {
            return ParsedReceipt(
                amount = 0.0,
                merchant = "Scanned Receipt",
                category = "General",
                rawText = ""
            )
        }

        val lines = ocrText.lines().map { it.trim() }.filter { it.isNotEmpty() }

        // 1. Merchant Extraction: Pick first non-numeric, non-date line with letters
        var merchant = "Scanned Receipt"
        for (line in lines.take(4)) {
            val clean = line.replace(Regex("[^a-zA-Z0-9\\s&'-]"), "").trim()
            if (clean.length in 3..40 && clean.any { it.isLetter() } && !clean.contains("receipt", ignoreCase = true) && !clean.contains("tax invoice", ignoreCase = true)) {
                merchant = clean
                break
            }
        }

        // 2. Amount Extraction: Prioritize lines containing "total", "net", "amount"
        var bestAmount = 0.0
        var foundExplicitTotal = false

        for (line in lines.reversed()) {
            val lower = line.lowercase()
            if (lower.contains("total") || lower.contains("grand total") || lower.contains("net") || lower.contains("subtotal")) {
                val extracted = extractNumbers(line)
                if (extracted > 0.0) {
                    bestAmount = extracted
                    foundExplicitTotal = true
                    break
                }
            }
        }

        // If no line with "total", search all lines and pick the largest sensible number
        if (!foundExplicitTotal) {
            var maxCandidate = 0.0
            for (line in lines) {
                // Avoid dates like 2026, 2025, 04/09
                if (line.contains("/") || line.contains("-") && line.length <= 10) continue
                val extracted = extractNumbers(line)
                if (extracted in 10.0..500000.0 && extracted > maxCandidate) {
                    maxCandidate = extracted
                }
            }
            bestAmount = maxCandidate
        }

        // 3. Category Inference
        val category = inferCategory(merchant, ocrText)

        return ParsedReceipt(
            amount = bestAmount,
            merchant = merchant,
            category = category,
            rawText = ocrText
        )
    }

    private fun extractNumbers(line: String): Double {
        val matcher = amountRegex.matcher(line)
        var lastNum = 0.0
        while (matcher.find()) {
            val numStr = matcher.group(1)?.replace(",", "") ?: ""
            val parsed = numStr.toDoubleOrNull() ?: 0.0
            if (parsed > 0.0) {
                lastNum = parsed
            }
        }
        return lastNum
    }

    private fun inferCategory(merchant: String, fullText: String): String {
        val combined = "$merchant $fullText".lowercase()
        return when {
            combined.contains("mart") || combined.contains("supermarket") || combined.contains("grocery") || combined.contains("store") || combined.contains("hyper") -> "Groceries"
            combined.contains("restaurant") || combined.contains("cafe") || combined.contains("coffee") || combined.contains("burger") || combined.contains("pizza") || combined.contains("food") || combined.contains("tea") || combined.contains("bakery") || combined.contains("kitchen") -> "Food & Dining"
            combined.contains("fuel") || combined.contains("petrol") || combined.contains("gas") || combined.contains("pso") || combined.contains("shell") || combined.contains("total") || combined.contains("uber") || combined.contains("careem") || combined.contains("indrive") -> "Transportation"
            combined.contains("electric") || combined.contains("water") || combined.contains("gas bill") || combined.contains("wifi") || combined.contains("internet") || combined.contains("ptcl") || combined.contains("bill") -> "Bills & Utilities"
            combined.contains("pharmacy") || combined.contains("med") || combined.contains("hospital") || combined.contains("clinic") || combined.contains("doctor") -> "Health"
            combined.contains("cinema") || combined.contains("movie") || combined.contains("game") || combined.contains("theatre") -> "Entertainment"
            combined.contains("outfitters") || combined.contains("khaadi") || combined.contains("cloth") || combined.contains("shoes") || combined.contains("wear") -> "Shopping"
            else -> "General"
        }
    }
}
