// lib/features/settings/providers/settings_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../core/services/unified_backup_service.dart';
import '../../../core/services/google_auth_service.dart';

class SettingsState {
  final bool darkMode;
  final bool biometricUnlock;
  final String userName;
  final String userEmail;
  final String userPhotoUrl;
  final DateTime? lastBackupAt;
  final bool hasLocalBackup;
  final bool hasGdriveBackup;
  final bool localBackupFileExists;
  final bool isBackingUp;
  final DateTime? notificationsViewedAt;

  const SettingsState({
    required this.darkMode,
    required this.biometricUnlock,
    required this.userName,
    required this.userEmail,
    required this.userPhotoUrl,
    this.lastBackupAt,
    this.hasLocalBackup = false,
    this.hasGdriveBackup = false,
    this.localBackupFileExists = false,
    this.isBackingUp = false,
    this.notificationsViewedAt,
  });

  SettingsState copyWith({
    bool? darkMode,
    bool? biometricUnlock,
    String? userName,
    String? userEmail,
    String? userPhotoUrl,
    DateTime? lastBackupAt,
    bool? hasLocalBackup,
    bool? hasGdriveBackup,
    bool? localBackupFileExists,
    bool? isBackingUp,
    DateTime? notificationsViewedAt,
    bool clearLastBackupAt = false,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      biometricUnlock: biometricUnlock ?? this.biometricUnlock,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      lastBackupAt: clearLastBackupAt ? null : (lastBackupAt ?? this.lastBackupAt),
      hasLocalBackup: hasLocalBackup ?? this.hasLocalBackup,
      hasGdriveBackup: hasGdriveBackup ?? this.hasGdriveBackup,
      localBackupFileExists: localBackupFileExists ?? this.localBackupFileExists,
      isBackingUp: isBackingUp ?? this.isBackingUp,
      notificationsViewedAt: notificationsViewedAt ?? this.notificationsViewedAt,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(const SettingsState(
          darkMode: false,
          biometricUnlock: true,
          userName: 'Vaultix User',
          userEmail: '',
          userPhotoUrl: '',
        )) {
    _loadSettings();
  }

  static const _keyDarkMode = 'setting_dark_mode';
  static const _keyBiometric = 'setting_biometric';

  static const _keyUserName = 'gdrive_connected_name';
  static const _keyUserEmail = 'gdrive_connected_email';
  static const _keyUserPhoto = 'gdrive_connected_photo';
  static const _keyNotificationsViewed = 'notifications_viewed_at';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ensure HapticHelper uses fallback/compatible mode (since we removed the UI selector)
      HapticHelper.hapticMode = 1;

      state = SettingsState(
        darkMode: prefs.getBool(_keyDarkMode) ?? false,
        biometricUnlock: prefs.getBool(_keyBiometric) ?? true,
        userName: prefs.getString(_keyUserName) ?? 'Vaultix User',
        userEmail: prefs.getString(_keyUserEmail) ?? '',
        userPhotoUrl: prefs.getString(_keyUserPhoto) ?? '',
        notificationsViewedAt: prefs.getString(_keyNotificationsViewed) != null 
            ? DateTime.tryParse(prefs.getString(_keyNotificationsViewed)!) 
            : null,
      );
      await refreshBackupMetadata();
    } catch (_) {
      // Keep defaults on failure
    }
  }

  Future<void> updateGoogleProfile(String? name, String? email, String? photoUrl) async {
    state = state.copyWith(
      userName: name ?? 'Vaultix User',
      userEmail: email ?? '',
      userPhotoUrl: photoUrl ?? '',
    );
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString(_keyUserName, name);
      await prefs.setString(_keyUserEmail, email ?? '');
      await prefs.setString(_keyUserPhoto, photoUrl ?? '');
    } else {
      await prefs.remove(_keyUserName);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserPhoto);
    }
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setBiometricUnlock(bool value) async {
    state = state.copyWith(biometricUnlock: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, value);
  }

  Future<void> refreshBackupMetadata() async {
    final meta = await UnifiedBackupService.loadMetadata();
    state = state.copyWith(
      lastBackupAt: meta.lastBackupAt,
      hasLocalBackup: meta.hasLocalBackup,
      hasGdriveBackup: meta.hasGdriveBackup,
      localBackupFileExists: meta.localFileExists,
    );
  }

  Future<BackupResult> performBackupNow() async {
    state = state.copyWith(isBackingUp: true);
    var result = await UnifiedBackupService.instance.performBackup();
    
    // Auto-reconnect and retry if Google Drive failed but user had a name (connected)
    if (!result.gdriveSuccess && state.userName != 'Vaultix User') {
      try {
        final profile = await GoogleAuthService.instance.signIn();
        if (profile != null) {
          result = await UnifiedBackupService.instance.performBackup();
        }
      } catch (_) {}
    }
    
    await refreshBackupMetadata();
    state = state.copyWith(isBackingUp: false);
    return result;
  }

  Future<void> markNotificationsViewed() async {
    final now = DateTime.now();
    state = state.copyWith(notificationsViewedAt: now);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotificationsViewed, now.toIso8601String());
  }

  Future<void> resetAllSettings() async {
    await UnifiedBackupService.instance.deleteBackups();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await GoogleAuthService.instance.signOut();
    // Re-initialize state to defaults
    state = const SettingsState(
      darkMode: false,
      biometricUnlock: true,
      userName: 'Vaultix User',
      userEmail: '',
      userPhotoUrl: '',
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
