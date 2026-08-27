package com.kharcha.kharcha

import java.util.Locale
import java.util.regex.Pattern

data class ParsedVoiceExpense(
    val merchant: String,
    val category: String,
    val amount: Double,
    val isIncome: Boolean,
    val rawText: String
)

object VoiceTransactionParser {

    fun parse(rawInput: String): ParsedVoiceExpense {
        val text = rawInput.trim().lowercase(Locale.ROOT)
        
        var amount = extractAmount(text)
        if (amount <= 0.0) {
            amount = 100.0 // Default fallback if no amount detected
        }

        val isIncome = text.contains("salary") || 
                       text.contains("tankhwah") || 
                       text.contains("received") || 
                       text.contains("freelance") ||
                       text.contains("wasool")

        val category = detectCategory(text, isIncome)
        val merchant = extractMerchant(text, category)

        return ParsedVoiceExpense(
            merchant = merchant,
            category = category,
            amount = amount,
            isIncome = isIncome,
            rawText = rawInput
        )
    }

    private fun extractAmount(text: String): Double {
        // 1. Pakistani colloquial denominations
        if (text.contains("derh sau") || text.contains("dedh sau")) return 150.0
        if (text.contains("dhai sau") || text.contains("dhai so")) return 250.0
        if (text.contains("paune do sau")) return 175.0
        if (text.contains("paune sau")) return 75.0

        // Multipliers: hazar (thousand), lakh (100k)
        val hazarPattern = Pattern.compile("(\\d+)\\s*(hazar|thousand|k)")
        val hazarMatcher = hazarPattern.matcher(text)
        if (hazarMatcher.find()) {
            val num = hazarMatcher.group(1)?.toDoubleOrNull() ?: 1.0
            return num * 1000.0
        }

        val lakhPattern = Pattern.compile("(\\d+)\\s*(lakh|lac)")
        val lakhMatcher = lakhPattern.matcher(text)
        if (lakhMatcher.find()) {
            val num = lakhMatcher.group(1)?.toDoubleOrNull() ?: 1.0
            return num * 100000.0
        }

        // 2. Standard numbers (e.g. 450, 1,200, 350.50)
        val numPattern = Pattern.compile("(\\d+[.,]?\\d*)")
        val numMatcher = numPattern.matcher(text.replace(",", ""))
        if (numMatcher.find()) {
            val numStr = numMatcher.group(1)
            val parsed = numStr?.toDoubleOrNull()
            if (parsed != null && parsed > 0) {
                return parsed
            }
        }

        return 0.0
    }

    private fun detectCategory(text: String, isIncome: Boolean): String {
        if (isIncome) return "Income"

        val foodKeywords = listOf("food", "lunch", "dinner", "breakfast", "burger", "pizza", "chai", "tea", "coffee", "starbucks", "biryani", "kfc", "mcdonalds", "sub", "sandwich", "restaurant", "roti", "naan", "cafe", "khana", "shawarma")
        for (kw in foodKeywords) {
            if (text.contains(kw)) return "Food & Dining"
        }

        val transportKeywords = listOf("uber", "careem", "petrol", "fuel", "indrive", "taxi", "rickshaw", "car", "bike", "parking", "toll", "bus", "ride")
        for (kw in transportKeywords) {
            if (text.contains(kw)) return "Transportation"
        }

        val groceryKeywords = listOf("grocery", "milk", "doodh", "dahi", "yogurt", "eggs", "bread", "supermarket", "fruits", "vegetables", "sabzi", "chicken", "mutton", "store", "sauda")
        for (kw in groceryKeywords) {
            if (text.contains(kw)) return "Groceries"
        }

        val billKeywords = listOf("electricity", "bijli", "gas", "water", "internet", "wifi", "bill", "recharge", "mobile", "easypaisa", "jazzcash")
        for (kw in billKeywords) {
            if (text.contains(kw)) return "Bills & Utilities"
        }

        val shoppingKeywords = listOf("clothes", "shirt", "shoes", "pants", "shopping", "mall", "daraz", "amazon", "kapre")
        for (kw in shoppingKeywords) {
            if (text.contains(kw)) return "Shopping"
        }

        val healthKeywords = listOf("medicine", "doctor", "hospital", "pharmacy", "panadol", "dawa")
        for (kw in healthKeywords) {
            if (text.contains(kw)) return "Health"
        }

        return "Other"
    }

    private fun extractMerchant(text: String, category: String): String {
        // Strip out common noise words
        val cleaned = text
            .replace(Regex("\\b(spent|maine|rupay|rupees|rs|pe|par|kharch|kiye|pay|kia|for|at|on|the|a|an)\\b"), " ")
            .replace(Regex("\\d+"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()

        if (cleaned.isNotEmpty() && cleaned.length in 2..25) {
            return cleaned.split(" ").filter { it.isNotBlank() }.joinToString(" ") { word ->
                word.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.ROOT) else it.toString() }
            }
        }

        return when (category) {
            "Food & Dining" -> "Food"
            "Transportation" -> "Transport"
            "Groceries" -> "Groceries"
            "Bills & Utilities" -> "Utility Bill"
            "Shopping" -> "Shopping"
            "Health" -> "Healthcare"
            "Income" -> "Income"
            else -> "Expense"
        }
    }
}
