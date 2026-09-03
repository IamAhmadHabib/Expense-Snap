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

        val isIncome = detectIncome(text)
        val brandPair = if (!isIncome) extractBrand(text) else null

        val category = brandPair?.first ?: detectCategory(text, isIncome)
        val merchant = brandPair?.second ?: extractMerchant(text, category)

        return ParsedVoiceExpense(
            merchant = merchant,
            category = category,
            amount = amount,
            isIncome = isIncome,
            rawText = rawInput
        )
    }

    private fun extractBrand(text: String): Pair<String, String>? {
        val brands = listOf(
            "kfc" to Pair("Food & Dining", "KFC"),
            "mcdonalds" to Pair("Food & Dining", "McDonald's"),
            "mcdonald" to Pair("Food & Dining", "McDonald's"),
            "cheezious" to Pair("Food & Dining", "Cheezious"),
            "ranchers" to Pair("Food & Dining", "Ranchers"),
            "subway" to Pair("Food & Dining", "Subway"),
            "optp" to Pair("Food & Dining", "OPTP"),
            "dominos" to Pair("Food & Dining", "Domino's"),
            "hardees" to Pair("Food & Dining", "Hardee's"),
            "gloria jeans" to Pair("Food & Dining", "Gloria Jean's"),
            "tim hortons" to Pair("Food & Dining", "Tim Hortons"),
            "starbucks" to Pair("Food & Dining", "Starbucks"),
            "d-watson" to Pair("Health", "D-Watson"),
            "fazal din" to Pair("Health", "Fazal Din"),
            "shifa" to Pair("Health", "Shifa Hospital"),
            "aga khan" to Pair("Health", "Aga Khan Hospital"),
            "cinepax" to Pair("Entertainment", "Cinepax"),
            "nueplex" to Pair("Entertainment", "Nueplex"),
            "cue cinema" to Pair("Entertainment", "Cue Cinema"),
            "netflix" to Pair("Entertainment", "Netflix"),
            "spotify" to Pair("Entertainment", "Spotify"),
            "pubg" to Pair("Entertainment", "PUBG"),
            "uber" to Pair("Transportation", "Uber"),
            "careem" to Pair("Transportation", "Careem"),
            "indrive" to Pair("Transportation", "InDrive"),
            "bykea" to Pair("Transportation", "Bykea"),
            "yango" to Pair("Transportation", "Yango"),
            "shell" to Pair("Transportation", "Shell"),
            "total" to Pair("Transportation", "Total Fuel"),
            "pso" to Pair("Transportation", "PSO"),
            "attock" to Pair("Transportation", "Attock Petroleum"),
            "imtiaz" to Pair("Shopping", "Imtiaz Super Market"),
            "carrefour" to Pair("Shopping", "Carrefour"),
            "alfatah" to Pair("Shopping", "Al-Fatah"),
            "chase up" to Pair("Shopping", "Chase Up"),
            "daraz" to Pair("Shopping", "Daraz"),
            "amazon" to Pair("Shopping", "Amazon"),
            "lesco" to Pair("Bills & Utilities", "LESCO"),
            "kelectric" to Pair("Bills & Utilities", "K-Electric"),
            "k-electric" to Pair("Bills & Utilities", "K-Electric"),
            "iesco" to Pair("Bills & Utilities", "IESCO"),
            "mepco" to Pair("Bills & Utilities", "MEPCO"),
            "gepco" to Pair("Bills & Utilities", "GEPCO"),
            "pesco" to Pair("Bills & Utilities", "PESCO"),
            "sui gas" to Pair("Bills & Utilities", "Sui Gas"),
            "ssgc" to Pair("Bills & Utilities", "SSGC"),
            "sngpl" to Pair("Bills & Utilities", "SNGPL"),
            "nayatel" to Pair("Bills & Utilities", "Nayatel"),
            "stormfiber" to Pair("Bills & Utilities", "StormFiber"),
            "ptcl" to Pair("Bills & Utilities", "PTCL"),
            "sadapay" to Pair("Bills & Utilities", "SadaPay"),
            "nayapay" to Pair("Bills & Utilities", "NayaPay")
        )
        for ((key, pair) in brands) {
            if (text.contains(key)) return pair
        }
        return null
    }

    private fun extractAmount(text: String): Double {
        // 1. Pakistani colloquial compound denominations
        if (text.contains("derh sau") || text.contains("dedh sau") || text.contains("derh so") || text.contains("dedh so")) return 150.0
        if (text.contains("dhai sau") || text.contains("dhai so") || text.contains("adhaai sau") || text.contains("adhai sau")) return 250.0
        if (text.contains("paune do sau") || text.contains("poney do sau")) return 175.0
        if (text.contains("sawa do sau")) return 225.0
        if (text.contains("paune sau") || text.contains("poney sau")) return 75.0
        if (text.contains("sawa sau")) return 125.0
        if (text.contains("derh hazar") || text.contains("dedh hazar") || text.contains("derh hazaar") || text.contains("dedh hazaar")) return 1500.0
        if (text.contains("dhai hazar") || text.contains("dhai hazaar") || text.contains("adhaai hazar")) return 2500.0
        if (text.contains("sade teen hazar") || text.contains("sarhe teen hazar")) return 3500.0
        if (text.contains("sade char hazar") || text.contains("sarhe char hazar")) return 4500.0
        if (text.contains("sade panch hazar") || text.contains("sarhe panch hazar")) return 5500.0
        if (text.contains("paune hazar") || text.contains("poney hazar")) return 750.0
        if (text.contains("sawa lakh")) return 125000.0
        if (text.contains("derh lakh") || text.contains("dedh lakh")) return 150000.0
        if (text.contains("dhai lakh") || text.contains("adhaai lakh")) return 250000.0
        if (text.contains("sade teen lakh") || text.contains("sarhe teen lakh")) return 350000.0

        // 2. Multipliers with strict word boundaries: hazar, lakh, crore, sau, k
        // Important: \b ensures Urdu prepositions "ka", "ki", "ke", "kay" NEVER match "k"
        val multiplierPattern = Pattern.compile("(\\d+(?:\\.\\d+)?)\\s*(crore\\b|kror\\b|cr\\b|lakh\\b|lac\\b|lacs\\b|laakh\\b|hazar\\b|hazaar\\b|thousand\\b|sau\\b|so\\b|k\\b)")
        val multiplierMatcher = multiplierPattern.matcher(text)
        if (multiplierMatcher.find()) {
            val base = multiplierMatcher.group(1)?.toDoubleOrNull() ?: 1.0
            val unit = multiplierMatcher.group(2)?.lowercase(Locale.ROOT) ?: ""
            when {
                unit in listOf("crore", "kror", "cr") -> return base * 10000000.0
                unit in listOf("lakh", "lac", "lacs", "laakh") -> return base * 100000.0
                unit in listOf("hazar", "hazaar", "thousand", "k") -> return base * 1000.0
                unit in listOf("sau", "so") -> return base * 100.0
            }
        }

        // 3. Standalone words
        if (text.contains("ek crore") || text.contains("ek kror")) return 10000000.0
        if (text.contains("ek lakh") || text.contains("aik lakh")) return 100000.0
        if (text.contains("ek hazar") || text.contains("aik hazar") || text.contains("hazar rupay") || text.contains("hazaar rupay")) return 1000.0
        if (text.contains("ek sau") || text.contains("aik sau") || text.contains("sau rupay") || text.contains("so rupay")) return 100.0

        // 4. Standard numbers (e.g. 300, 450, 1,200, 350.50)
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

    private fun detectIncome(text: String): Boolean {
        val explicitExpense = listOf(
            "kharch", "kharcha", "lagaye", "lagaya", "diye", "diya", "bhare", "bhara",
            "spent", "paid", "bill", "ada", "adaa", "kharida", "kharidi"
        ).any { text.contains(it) }

        if (explicitExpense) return false

        val incomeKeywords = listOf(
            "salary", "tankhwah", "tankhah", "tanha", "wazifa", "stipend", "bonus",
            "freelance", "client", "upwork", "fiverr", "kamayi", "munafa", "profit",
            "cashback", "refund", "eidi", "salami", "wasool", "received", "income",
            "aaye", "aye", "milay", "mile", "jama", "deposit"
        )
        return incomeKeywords.any { text.contains(it) }
    }

    private fun detectCategory(text: String, isIncome: Boolean): String {
        if (isIncome) return "Income"

        // 1. Food & Dining
        val foodKeywords = listOf(
            "food", "lunch", "dinner", "breakfast", "burger", "pizza", "chai", "tea", "coffee",
            "starbucks", "biryani", "pulao", "karahi", "handi", "tikka", "boti", "kebab", "kabab",
            "nihari", "haleem", "daal", "sabzi", "roti", "salan", "naan", "paratha", "pratha",
            "roll", "shawarma", "shwarma", "kfc", "mcdonalds", "mcdonald", "subway", "optp",
            "hardees", "dominos", "cheezious", "ranchers", "gloria jeans", "tim hortons",
            "samosa", "samose", "pakora", "pakoray", "chaat", "gol gappay", "gol gappe", "dahi bhallay",
            "jalebi", "halwa", "mithai", "ice cream", "kulfi", "falooda", "doodh patti", "lassi",
            "juice", "shake", "nashta", "sehri", "iftar", "iftari", "snack", "snacks", "restaurant",
            "cafe", "dhabba", "dhaba", "hotel", "canteen", "khana", "khanay", "broast"
        )
        for (kw in foodKeywords) {
            if (text.contains(kw)) return "Food & Dining"
        }

        // 2. Bills & Utilities
        val billKeywords = listOf(
            "electricity", "bijli", "electric", "lesco", "kelectric", "k-electric", "iesco",
            "mepco", "gepco", "pesco", "bill", "gas", "sui gas", "ssgc", "sngpl", "cylinder",
            "water", "pani", "wasa", "tanker", "internet", "wifi", "ptcl", "nayatel", "stormfiber",
            "mobile", "phone", "sim", "recharge", "load", "balance", "package", "jazz", "telenor",
            "zong", "ufone", "easypaisa", "jazzcash", "fee", "fees", "tuition", "academy",
            "rent", "kiraya makaan", "maintenance", "kamiti", "committee"
        )
        for (kw in billKeywords) {
            if (text.contains(kw)) return "Bills & Utilities"
        }

        // 3. Health & Medical
        val healthKeywords = listOf(
            "medicine", "medicines", "doctor", "hospital", "pharmacy", "panadol", "dawa", "dawai",
            "dawaai", "tablet", "syrup", "injection", "drip", "disprin", "arinac", "brufen",
            "augmentin", "bandage", "checkup", "clinic", "dispensary", "medical store", "d-watson",
            "fazal din", "shifa", "aga khan", "lab", "test", "blood test", "x-ray", "ultrasound",
            "dentist"
        )
        for (kw in healthKeywords) {
            if (text.contains(kw)) return "Health"
        }

        // 4. Entertainment
        val entertainmentKeywords = listOf(
            "movie", "cinema", "film", "cue cinema", "cinepax", "nueplex", "popcorn", "netflix",
            "spotify", "youtube", "game", "gaming", "steam", "playstation", "ps5", "pubg", "outing",
            "picnic", "park", "bowling", "snooker", "cricket", "match", "party", "treat", "concert"
        )
        for (kw in entertainmentKeywords) {
            if (text.contains(kw)) return "Entertainment"
        }

        // 5. Transportation
        val transportKeywords = listOf(
            "uber", "careem", "indrive", "bykea", "yango", "petrol", "fuel", "diesel", "cng",
            "hawa", "puncture", "panchar", "mobil oil", "servicing", "car wash", "rickshaw",
            "rikshaw", "chingchi", "chinchi", "taxi", "cab", "bus", "wagon", "van", "metro",
            "speedo", "orange line", "train", "railway", "ticket", "flight", "pia", "fare",
            "kiraya", "karaya", "toll", "m-tag", "mtag", "parking", "chalan", "challan", "ride",
            "car", "bike"
        )
        for (kw in transportKeywords) {
            if (text.contains(kw)) return "Transportation"
        }

        // 6. Groceries & Shopping
        val shoppingKeywords = listOf(
            "grocery", "groceries", "sauda", "rashan", "ration", "doodh", "milk", "dahi", "yogurt",
            "makhan", "butter", "paneer", "cheese", "anday", "ande", "eggs", "bread", "double roti",
            "atta", "flour", "chawal", "rice", "cheeni", "sugar", "patti", "oil", "ghee", "masalay",
            "spices", "sabzi", "vegetables", "aaloo", "pyaz", "tamatar", "gosht", "meat", "chicken",
            "beef", "mutton", "machli", "fish", "phal", "fruits", "sayb", "kela", "aam", "supermarket",
            "mart", "store", "imtiaz", "carrefour", "alfatah", "chase up", "clothes", "shirt",
            "shoes", "pants", "shopping", "mall", "daraz", "amazon", "kapray", "kapre", "jora",
            "suit", "shalwar", "kameez", "kurta", "jootay", "joote", "chappal", "slippers",
            "sneakers", "socks", "bag", "wallet", "watch", "ghari", "makeup", "cosmetics",
            "perfume", "itr", "attar", "bazaar", "market", "emporium", "packages", "centaurus",
            "dolmen"
        )
        for (kw in shoppingKeywords) {
            if (text.contains(kw)) return "Shopping"
        }

        return "Other"
    }

    private fun extractMerchant(text: String, category: String): String {
        // Strip out noise words in English & Urdu
        val cleaned = text
            .replace(Regex("\\b(spent|maine|meine|mene|humne|hum ne|rupay|rupaye|rupees|rs|pkr|pe|par|mein|mai|se|ko|ka|ki|ke|kay|k|kharch|kharcha|kharche|kiye|kia|diye|diya|lagaye|lagaya|bhare|bhara|pay|paid|ada|adaa|for|at|on|in|the|a|an|aur|and|say|wala|wali|wale)\\b"), " ")
            .replace(Regex("\\b(crore|kror|lakh|lac|lacs|hazar|hazaar|thousand|sau|so)\\b"), " ")
            .replace(Regex("\\d+"), " ")
            .replace(Regex("\\s+"), " ")
            .trim()

        if (cleaned.isNotEmpty() && cleaned.length in 2..30) {
            return cleaned.split(" ").filter { it.isNotBlank() }.joinToString(" ") { word ->
                word.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.ROOT) else it.toString() }
            }
        }

        return when (category) {
            "Food & Dining" -> "Food"
            "Transportation" -> "Transport"
            "Bills & Utilities" -> "Utility Bill"
            "Shopping" -> "Shopping"
            "Health" -> "Healthcare"
            "Entertainment" -> "Entertainment"
            "Income" -> "Income"
            else -> "Expense"
        }
    }
}
