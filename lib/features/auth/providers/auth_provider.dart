// lib/features/auth/providers/auth_provider.dart
import 'dart:convert';
import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../../../core/services/unified_backup_service.dart';

enum AuthStatus {
  needsSetup,
  locked,
  awaiting2FA,
  unlocked,
}

class AuthState {
  final AuthStatus status;
  final String? recoveryKey;
  final String? errorMessage;
  final bool hasTotpEnabled;

  AuthState({
    required this.status,
    this.recoveryKey,
    this.errorMessage,
    this.hasTotpEnabled = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? recoveryKey,
    String? errorMessage,
    bool? hasTotpEnabled,
  }) {
    return AuthState(
      status: status ?? this.status,
      recoveryKey: recoveryKey ?? this.recoveryKey,
      errorMessage: errorMessage ?? this.errorMessage,
      hasTotpEnabled: hasTotpEnabled ?? this.hasTotpEnabled,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(status: AuthStatus.locked)) {
    checkSetup();
  }

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyPwHash = 'vaultix_master_password_hash';
  static const _keyRecovery = 'vaultix_recovery_key';
  static const _keyTotpSecret = 'vaultix_totp_secret';
  static const _key2faInstallVerified = 'vaultix_2fa_install_verified';

  Future<bool> _is2faInstallVerified() async {
    final v = await _storage.read(key: _key2faInstallVerified);
    return v == 'true';
  }

  Future<void> _set2faInstallVerified(bool value) async {
    if (value) {
      await _storage.write(key: _key2faInstallVerified, value: 'true');
    } else {
      await _storage.delete(key: _key2faInstallVerified);
    }
  }

  Future<void> clear2faInstallVerified() => _set2faInstallVerified(false);

  Future<AuthStatus> _statusAfterPrimaryUnlock() async {
    final totpSecret = await _storage.read(key: _keyTotpSecret);
    if (totpSecret != null && totpSecret.isNotEmpty) {
      final verified = await _is2faInstallVerified();
      return verified ? AuthStatus.unlocked : AuthStatus.awaiting2FA;
    }
    return AuthStatus.unlocked;
  }

  Future<void> checkSetup() async {
    final hash = await _storage.read(key: _keyPwHash);
    final totpSecret = await _storage.read(key: _keyTotpSecret);
    final hasTotp = totpSecret != null && totpSecret.isNotEmpty;
    if (hash == null || hash.isEmpty) {
      final recovery = _generateRecoveryKey();
      state = AuthState(
        status: AuthStatus.needsSetup,
        recoveryKey: recovery,
        hasTotpEnabled: hasTotp,
      );
    } else {
      state = AuthState(status: AuthStatus.locked, hasTotpEnabled: hasTotp);
    }
  }

  String _generateRecoveryKey() {
    final rand = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String part() => List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return '${part()}-${part()}-${part()}-${part()}';
  }

  Future<bool> setupMasterPassword(String password, String recoveryKey) async {
    if (password.length < 6) {
      state = state.copyWith(errorMessage: 'Password must be at least 6 characters.');
      return false;
    }
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();
    
    await _storage.write(key: _keyPwHash, value: hash);
    await _storage.write(key: _keyRecovery, value: recoveryKey.toUpperCase().trim());
    await _storage.write(key: 'master_key', value: password);
    
    state = AuthState(status: AuthStatus.unlocked, hasTotpEnabled: false);
    return true;
  }

  Future<bool> unlock(String password) async {
    final storedHash = await _storage.read(key: _keyPwHash);
    if (storedHash == null) {
      state = AuthState(status: AuthStatus.needsSetup);
      return false;
    }
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();

    if (storedHash == hash) {
      await _storage.write(key: 'master_key', value: password);
      final nextStatus = await _statusAfterPrimaryUnlock();
      state = state.copyWith(status: nextStatus, errorMessage: null);
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Incorrect master password.');
      return false;
    }
  }

  Future<bool> resetWithRecoveryKey(String key, String newPassword) async {
    final storedKey = await _storage.read(key: _keyRecovery);
    if (storedKey == null) return false;

    if (storedKey.trim().toUpperCase() == key.trim().toUpperCase()) {
      if (newPassword.length < 6) {
        state = state.copyWith(errorMessage: 'Password must be at least 6 characters.');
        return false;
      }
      final bytes = utf8.encode(newPassword);
      final hash = sha256.convert(bytes).toString();

      await _storage.write(key: _keyPwHash, value: hash);
      await _storage.write(key: 'master_key', value: newPassword);
      final hasTotp = await isTotpEnabled();
      state = AuthState(status: AuthStatus.unlocked, hasTotpEnabled: hasTotp);
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Invalid recovery key.');
      return false;
    }
  }

  void lock() {
    state = state.copyWith(status: AuthStatus.locked, errorMessage: null);
  }

  Future<void> unlockBiometrics() async {
    final nextStatus = await _statusAfterPrimaryUnlock();
    state = state.copyWith(status: nextStatus, errorMessage: null);
  }

  Future<bool> isTotpEnabled() async {
    final secret = await _storage.read(key: _keyTotpSecret);
    return secret != null && secret.isNotEmpty;
  }

  Future<String?> getTotpSecret() async {
    return await _storage.read(key: _keyTotpSecret);
  }

  Future<void> enableTotp(String secret) async {
    await _storage.write(key: _keyTotpSecret, value: secret);
    await _set2faInstallVerified(true);
    state = state.copyWith(errorMessage: null, hasTotpEnabled: true);
    UnifiedBackupService.instance.performBackup();
  }

  Future<void> disableTotp() async {
    await _storage.delete(key: _keyTotpSecret);
    await _set2faInstallVerified(false);
    state = state.copyWith(errorMessage: null, hasTotpEnabled: false);
    UnifiedBackupService.instance.performBackup();
  }

  void complete2FA() {
    if (state.status == AuthStatus.awaiting2FA) {
      _set2faInstallVerified(true);
      state = state.copyWith(status: AuthStatus.unlocked, errorMessage: null);
    }
  }

  Future<void> initializeWithRestoredPassword(String password) async {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();
    await _storage.write(key: _keyPwHash, value: hash);
    await _storage.write(key: 'master_key', value: password);
    
    final existingRecovery = await _storage.read(key: _keyRecovery);
    if (existingRecovery == null || existingRecovery.isEmpty) {
      final recovery = _generateRecoveryKey();
      await _storage.write(key: _keyRecovery, value: recovery);
    }
    
    final totpSecret = await _storage.read(key: _keyTotpSecret);
    if (totpSecret != null && totpSecret.isNotEmpty) {
      await _set2faInstallVerified(false);
      state = AuthState(status: AuthStatus.awaiting2FA, hasTotpEnabled: true);
    } else {
      state = AuthState(status: AuthStatus.unlocked, hasTotpEnabled: false);
    }
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
