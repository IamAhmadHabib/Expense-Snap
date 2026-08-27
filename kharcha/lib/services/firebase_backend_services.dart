import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../core/app_session.dart';
import 'app_services.dart';

class FirebaseAuthService implements AuthService {
  final firebase_auth.FirebaseAuth _auth;

  FirebaseAuthService({firebase_auth.FirebaseAuth? auth})
    : _auth = auth ?? firebase_auth.FirebaseAuth.instance;

  @override
  AppSession get currentSession => _sessionFromUser(_auth.currentUser);

  @override
  Future<AppSession> restoreSession() async {
    return _sessionFromUser(_auth.currentUser);
  }

  @override
  Future<AppSession> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    return _sessionFromUser(credential.user);
  }

  @override
  Future<AppSession> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw StateError('Google sign-in was cancelled.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return _sessionFromUser(result.user);
  }

  @override
  Future<AppSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _sessionFromUser(credential.user);
  }

  @override
  Future<AppSession> createAccountWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    final cleanedDisplayName = displayName?.trim();
    if (user != null &&
        cleanedDisplayName != null &&
        cleanedDisplayName.isNotEmpty) {
      await user.updateDisplayName(cleanedDisplayName);
      await user.reload();
    }
    return _sessionFromUser(_auth.currentUser ?? user);
  }

  @override
  Future<AppSession> signOut() async {
    await _auth.signOut();
    return const AppSession.signedOut();
  }

  AppSession _sessionFromUser(firebase_auth.User? user) {
    if (user == null) {
      return const AppSession.signedOut();
    }
    if (user.isAnonymous) {
      return AppSession.anonymous(user.uid);
    }
    return AppSession.signedIn(
      userId: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }
}
