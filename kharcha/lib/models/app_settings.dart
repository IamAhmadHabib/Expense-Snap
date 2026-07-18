class AppSettings {
  final String userName;
  final String profileEmail;
  final double monthlyBudget;
  final String currencySymbol;
  final List<String> selectedCategories;
  final bool notificationsEnabled;
  final bool monthlyDigest;
  final bool budgetAlerts;
  final bool spendingInsights;
  final bool darkMode;
  final String language;
  final int resetDay;

  const AppSettings({
    this.userName = 'Ahmad',
    this.profileEmail = '',
    this.monthlyBudget = 0,
    this.currencySymbol = 'Rs.',
    this.selectedCategories = const [],
    this.notificationsEnabled = true,
    this.monthlyDigest = true,
    this.budgetAlerts = true,
    this.spendingInsights = true,
    this.darkMode = false,
    this.language = 'English',
    this.resetDay = 1,
  });

  AppSettings copyWith({
    String? userName,
    String? profileEmail,
    double? monthlyBudget,
    String? currencySymbol,
    List<String>? selectedCategories,
    bool? notificationsEnabled,
    bool? monthlyDigest,
    bool? budgetAlerts,
    bool? spendingInsights,
    bool? darkMode,
    String? language,
    int? resetDay,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      profileEmail: profileEmail ?? this.profileEmail,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      monthlyDigest: monthlyDigest ?? this.monthlyDigest,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      spendingInsights: spendingInsights ?? this.spendingInsights,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      resetDay: resetDay ?? this.resetDay,
    );
  }

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'profileEmail': profileEmail,
    'monthlyBudget': monthlyBudget,
    'currencySymbol': currencySymbol,
    'selectedCategories': selectedCategories,
    'notificationsEnabled': notificationsEnabled,
    'monthlyDigest': monthlyDigest,
    'budgetAlerts': budgetAlerts,
    'spendingInsights': spendingInsights,
    'darkMode': darkMode,
    'language': language,
    'resetDay': resetDay,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      userName: json['userName'] as String? ?? 'Ahmad',
      profileEmail: json['profileEmail'] as String? ?? '',
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 0,
      currencySymbol: json['currencySymbol'] as String? ?? 'Rs.',
      selectedCategories:
          (json['selectedCategories'] as List<dynamic>?)
              ?.map((value) => value as String)
              .toList() ??
          const [],
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      monthlyDigest: json['monthlyDigest'] as bool? ?? true,
      budgetAlerts: json['budgetAlerts'] as bool? ?? true,
      spendingInsights: json['spendingInsights'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'English',
      resetDay: json['resetDay'] as int? ?? 1,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.userName == userName &&
        other.profileEmail == profileEmail &&
        other.monthlyBudget == monthlyBudget &&
        other.currencySymbol == currencySymbol &&
        _sameList(other.selectedCategories, selectedCategories) &&
        other.notificationsEnabled == notificationsEnabled &&
        other.monthlyDigest == monthlyDigest &&
        other.budgetAlerts == budgetAlerts &&
        other.spendingInsights == spendingInsights &&
        other.darkMode == darkMode &&
        other.language == language &&
        other.resetDay == resetDay;
  }

  @override
  int get hashCode => Object.hash(
    userName,
    profileEmail,
    monthlyBudget,
    currencySymbol,
    Object.hashAll(selectedCategories),
    notificationsEnabled,
    monthlyDigest,
    budgetAlerts,
    spendingInsights,
    darkMode,
    language,
    resetDay,
  );

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}
