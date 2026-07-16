enum AppAuthStatus { unknown, signedOut, anonymous, signedIn }

enum AppStartDestination { onboarding, dashboard }

class AppSession {
  final AppAuthStatus status;
  final String? userId;
  final String? email;
  final String? displayName;

  const AppSession({
    required this.status,
    this.userId,
    this.email,
    this.displayName,
  });

  const AppSession.unknown() : this(status: AppAuthStatus.unknown);

  const AppSession.signedOut() : this(status: AppAuthStatus.signedOut);

  const AppSession.anonymous(String userId)
    : this(status: AppAuthStatus.anonymous, userId: userId);

  const AppSession.signedIn({
    required String userId,
    String? email,
    String? displayName,
  }) : this(
         status: AppAuthStatus.signedIn,
         userId: userId,
         email: email,
         displayName: displayName,
       );

  bool get isAuthenticated {
    return status == AppAuthStatus.signedIn ||
        status == AppAuthStatus.anonymous;
  }

  @override
  bool operator ==(Object other) {
    return other is AppSession &&
        other.status == status &&
        other.userId == userId &&
        other.email == email &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(status, userId, email, displayName);
}
