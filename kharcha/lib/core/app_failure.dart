class AppFailure {
  final String code;
  final String message;
  final bool isRetryable;
  final Map<String, String> details;

  const AppFailure({
    required this.code,
    required this.message,
    this.isRetryable = false,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    'isRetryable': isRetryable,
    'details': details,
  };

  factory AppFailure.fromJson(Map<String, dynamic> json) {
    return AppFailure(
      code: json['code'] as String,
      message: json['message'] as String,
      isRetryable: json['isRetryable'] as bool? ?? false,
      details:
          (json['details'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const {},
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppFailure &&
        other.code == code &&
        other.message == message &&
        other.isRetryable == isRetryable &&
        _sameMap(other.details, details);
  }

  @override
  int get hashCode => Object.hash(
    code,
    message,
    isRetryable,
    Object.hashAll(
      details.entries.map((entry) => '${entry.key}:${entry.value}'),
    ),
  );

  static bool _sameMap(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
