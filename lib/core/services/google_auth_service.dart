// lib/core/services/google_auth_service.dart
import 'dart:developer' as developer;

import 'package:google_sign_in/google_sign_in.dart';

/// Wraps google_sign_in with Drive scope so the user picks their real Google
/// account from the OS account chooser — no manual text entry needed.
class GoogleAuthService {
  GoogleAuthService._();
  static final instance = GoogleAuthService._();

  static const _driveScope = 'https://www.googleapis.com/auth/drive.appdata';

  /// Web OAuth client ID from Firebase / Google Cloud Console (type: Web application).
  /// Required only for Google Drive backup — not for basic profile sign-in.
  /// Set via --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  final _gsi = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  late final GoogleSignIn _gsiWithDrive = GoogleSignIn(
        serverClientId: _webClientId.isEmpty ? null : _webClientId,
        scopes: const ['email', 'profile', _driveScope],
      );

  Future<GoogleSignInAccount?> _signInSilentlyWithFallback() async {
    return await _gsiWithDrive.signInSilently() ?? await _gsi.signInSilently();
  }

  /// Shows the native Google account picker (always — never silent).
  /// Returns null on cancel; throws [GoogleSignInException] on failure.
  Future<GoogleProfile?> signIn() async {
    try {
      final account = await _gsiWithDrive.signIn();
      if (account == null) return null;

      return _profileFromAccount(account);
    } on Exception catch (e, st) {
      developer.log('Google sign-in failed', name: 'GoogleAuthService', error: e, stackTrace: st);
      throw GoogleSignInException(e.toString());
    }
  }

  /// Signs the user out and clears cached credentials.
  Future<void> signOut() async {
    try {
      await _gsi.signOut();
      await _gsi.disconnect();
      await _gsiWithDrive.signOut();
      await _gsiWithDrive.disconnect();
    } catch (_) {}
  }

  /// Returns the active Google access token for Drive API access.
  Future<String?> getAccessToken() async {
    try {
      var account = await _gsiWithDrive.signInSilently();
      if (account == null) {
        print('GoogleAuthService getAccessToken: _gsiWithDrive.signInSilently() returned null. Attempting full signIn()...');
        account = await _gsiWithDrive.signIn();
      }
      if (account == null) {
        print('GoogleAuthService getAccessToken: User cancelled or sign in failed.');
        return null;
      }

      final granted = await _gsiWithDrive.requestScopes([_driveScope]);
      if (!granted) {
        print('GoogleAuthService getAccessToken: requestScopes returned false');
        return null;
      }

      final scopedAccount = _gsiWithDrive.currentUser ?? account;
      final auth = await scopedAccount.authentication;
      print('GoogleAuthService getAccessToken: Success, token=${auth.accessToken != null}');
      return auth.accessToken;
    } on Exception catch (e, st) {
      developer.log('Drive token fetch failed', name: 'GoogleAuthService', error: e, stackTrace: st);
      print('GoogleAuthService getAccessToken exception: $e');
      return null;
    }
  }

  /// Returns the signed-in account without prompting (null if not signed in).
  Future<GoogleProfile?> currentUser() async {
    try {
      final account = await _signInSilentlyWithFallback();
      if (account == null) return null;
      return _profileFromAccount(account);
    } catch (_) {
      return null;
    }
  }

  GoogleProfile _profileFromAccount(GoogleSignInAccount account) {
    return GoogleProfile(
      name: account.displayName ?? account.email.split('@').first,
      email: account.email,
      photoUrl: account.photoUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(account.displayName ?? account.email)}&background=6338F6&color=fff&size=128&bold=true',
    );
  }
}

class GoogleProfile {
  const GoogleProfile({
    required this.name,
    required this.email,
    required this.photoUrl,
  });
  final String name;
  final String email;
  final String photoUrl;
}

class GoogleSignInException implements Exception {
  GoogleSignInException(this.message);
  final String message;

  @override
  String toString() => message;
}
