// lib/core/services/unified_backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/vault/models/password_entry.dart';
import 'google_drive_service.dart';
import 'secure_storage_service.dart';

class BackupResult {
  const BackupResult({
    required this.localSuccess,
    required this.gdriveSuccess,
    this.error,
  });

  final bool localSuccess;
  final bool gdriveSuccess;
  final String? error;

  bool get anySuccess => localSuccess || gdriveSuccess;
  bool get fullSuccess => localSuccess && gdriveSuccess;
}

class RestorePayload {
  const RestorePayload({
    required this.entries,
    this.recoveryKey,
    this.totpSecret,
    this.backedUpAt,
  });

  final List<PasswordEntry> entries;
  final String? recoveryKey;
  final String? totpSecret;
  final DateTime? backedUpAt;
}

class UnifiedBackupService {
  UnifiedBackupService._();
  static final instance = UnifiedBackupService._();

  static const _backupVersion = 1;
  static const _keyLastBackupAt = 'last_backup_at';
  static const _keyLastBackupLocal = 'last_backup_local';
  static const _keyLastBackupGdrive = 'last_backup_gdrive';
  static const _keyGdrivePayload = 'gdrive_backup_payload';

  static const _backupPaths = [
    '/storage/emulated/0/Download/vaultix_local_backup.enc',
    '/storage/emulated/0/Documents/vaultix_local_backup.enc',
  ];

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Deletes all local backups and Google Drive backup
  Future<void> deleteBackups() async {
    for (final path in _backupPaths) {
      final file = File(path);
      if (file.existsSync()) {
        try { file.deleteSync(); } catch (_) {}
      }
    }
    await GoogleDriveService.instance.deleteBackup();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastBackupAt);
    await prefs.remove(_keyLastBackupLocal);
    await prefs.remove(_keyLastBackupGdrive);
    await prefs.remove(_keyGdrivePayload);
  }

  enc.Key _deriveKey(String masterPassword) {
    final hashBytes = sha256.convert(utf8.encode(masterPassword)).bytes;
    return enc.Key(Uint8List.fromList(hashBytes));
  }

  String _encryptJson(Map<String, dynamic> payload, String masterPassword) {
    final key = _deriveKey(masterPassword);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(jsonEncode(payload), iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  dynamic _decryptToDynamic(String backupData, String masterPassword) {
    final parts = backupData.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid backup data format.');
    }

    final iv = enc.IV.fromBase64(parts[0]);
    final key = _deriveKey(masterPassword);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted =
        encrypter.decrypt(enc.Encrypted.fromBase64(parts[1]), iv: iv);
    return jsonDecode(decrypted);
  }

  Future<Map<String, dynamic>> _readPayloadMap(List<PasswordEntry> entries) async {
    final recoveryKey = await _storage.read(key: 'vaultix_recovery_key');
    final totpSecret = await _storage.read(key: 'vaultix_totp_secret');
    return {
      'version': _backupVersion,
      'backedUpAt': DateTime.now().toUtc().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'recoveryKey': recoveryKey,
      'totpSecret': totpSecret,
    };
  }

  RestorePayload _parseDecrypted(dynamic decrypted) {
    if (decrypted is List) {
      final entries =
          decrypted.map((item) => PasswordEntry.fromJson(item)).toList();
      return RestorePayload(entries: entries);
    }

    if (decrypted is Map<String, dynamic>) {
      final rawEntries = decrypted['entries'] as List<dynamic>? ?? [];
      final entries =
          rawEntries.map((item) => PasswordEntry.fromJson(item)).toList();
      final backedUpAtRaw = decrypted['backedUpAt'] as String?;
      return RestorePayload(
        entries: entries,
        recoveryKey: decrypted['recoveryKey'] as String?,
        totpSecret: decrypted['totpSecret'] as String?,
        backedUpAt:
            backedUpAtRaw != null ? DateTime.tryParse(backedUpAtRaw) : null,
      );
    }

    throw const FormatException('Unrecognized backup payload.');
  }

  RestorePayload decryptBackup(String backupData, String masterPassword) {
    final decrypted = _decryptToDynamic(backupData, masterPassword);
    return _parseDecrypted(decrypted);
  }

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Just request normal storage permission first. 
        // Asking for manageExternalStorage indiscriminately takes the user out of the app.
        final status = await Permission.storage.request();
        if (status.isGranted) {
          return true;
        }
        
        // If they really need it (Android 11+ legacy), only then try.
        if (await Permission.manageExternalStorage.isGranted) {
            return true;
        }
        
        // Let's try to request it if standard storage is denied and we are on A11+
        // But this opens a settings activity. It might be better to just fail gracefully.
        return false;
      }
      return !Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasLocalBackup() async {
    for (final path in _backupPaths) {
      if (await File(path).exists()) return true;
    }
    return false;
  }

  Future<DateTime?> getLocalBackupModifiedAt() async {
    DateTime? latest;
    for (final path in _backupPaths) {
      final file = File(path);
      if (await file.exists()) {
        final modified = await file.lastModified();
        if (latest == null || modified.isAfter(latest)) {
          latest = modified;
        }
      }
    }
    return latest;
  }

  Future<String?> readLocalBackupString() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) return null;

    for (final path in _backupPaths) {
      final file = File(path);
      if (await file.exists()) {
        return file.readAsString();
      }
    }
    return null;
  }

  Future<void> _writeLocalBackup(String backupString) async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) throw Exception('Storage permission denied.');

    for (final path in _backupPaths) {
      final file = File(path);
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      await file.writeAsString(backupString, flush: true);
    }
  }

  Future<void> _saveBackupMetadata({
    required bool localSuccess,
    required bool gdriveSuccess,
    String? encryptedPayload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (localSuccess || gdriveSuccess) {
      await prefs.setString(_keyLastBackupAt, DateTime.now().toUtc().toIso8601String());
    }
    await prefs.setBool(_keyLastBackupLocal, localSuccess);
    await prefs.setBool(_keyLastBackupGdrive, gdriveSuccess);
    if (gdriveSuccess && encryptedPayload != null) {
      await prefs.setString(_keyGdrivePayload, encryptedPayload);
    }
  }

  Future<BackupResult> performBackup({List<PasswordEntry>? entries}) async {
    try {
      final masterKey = await _storage.read(key: 'master_key');
      if (masterKey == null || masterKey.isEmpty) {
        return const BackupResult(
          localSuccess: false,
          gdriveSuccess: false,
          error: 'Vault is locked — unlock first to back up.',
        );
      }

      final vaultEntries = entries ?? await SecureStorageService.instance.loadEntries();
      final payload = await _readPayloadMap(vaultEntries);
      final encrypted = _encryptJson(payload, masterKey);

      var localSuccess = false;
      try {
        await _writeLocalBackup(encrypted);
        localSuccess = true;
      } catch (_) {}

      var gdriveSuccess = false;
      try {
        gdriveSuccess = await GoogleDriveService.instance.uploadBackup(encrypted);
      } catch (_) {}

      await _saveBackupMetadata(
        localSuccess: localSuccess,
        gdriveSuccess: gdriveSuccess,
        encryptedPayload: gdriveSuccess ? encrypted : null,
      );

      return BackupResult(
        localSuccess: localSuccess,
        gdriveSuccess: gdriveSuccess,
        error: !localSuccess && !gdriveSuccess ? 'Backup failed.' : null,
      );
    } catch (e) {
      return BackupResult(
        localSuccess: false,
        gdriveSuccess: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> applyRestoredPayload(
    RestorePayload payload,
    String masterPassword,
  ) async {
    await SecureStorageService.instance.saveEntries(payload.entries, skipBackup: true);

    final pwHash = sha256.convert(utf8.encode(masterPassword)).toString();
    await _storage.write(key: 'vaultix_master_password_hash', value: pwHash);
    await _storage.write(key: 'master_key', value: masterPassword);

    if (payload.recoveryKey != null && payload.recoveryKey!.isNotEmpty) {
      await _storage.write(key: 'vaultix_recovery_key', value: payload.recoveryKey!);
    }
    if (payload.totpSecret != null && payload.totpSecret!.isNotEmpty) {
      await _storage.write(key: 'vaultix_totp_secret', value: payload.totpSecret!);
    } else {
      await _storage.delete(key: 'vaultix_totp_secret');
    }

    await _storage.delete(key: 'vaultix_2fa_install_verified');
    return true;
  }

  Future<bool> restoreFromLocalBackup(String masterPassword) async {
    try {
      final backupString = await readLocalBackupString();
      if (backupString == null || backupString.isEmpty) return false;

      final payload = decryptBackup(backupString, masterPassword);
      return applyRestoredPayload(payload, masterPassword);
    } catch (_) {
      return false;
    }
  }

  Future<String?> fetchGdriveBackupString() async {
    final downloaded = await GoogleDriveService.instance.downloadBackup();
    if (downloaded != null && downloaded.isNotEmpty) return downloaded;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGdrivePayload);
  }

  Future<bool> restoreFromGdriveBackup(String masterPassword) async {
    try {
      final backupString = await fetchGdriveBackupString();
      if (backupString == null || backupString.isEmpty) return false;

      final payload = decryptBackup(backupString, masterPassword);
      return applyRestoredPayload(payload, masterPassword);
    } catch (_) {
      return false;
    }
  }

  static Future<BackupMetadata> loadMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final atRaw = prefs.getString(_keyLastBackupAt);
    return BackupMetadata(
      lastBackupAt: atRaw != null ? DateTime.tryParse(atRaw) : null,
      hasLocalBackup: prefs.getBool(_keyLastBackupLocal) ?? false,
      hasGdriveBackup: prefs.getBool(_keyLastBackupGdrive) ?? false,
      localFileExists: await instance.hasLocalBackup(),
    );
  }
}

class BackupMetadata {
  const BackupMetadata({
    this.lastBackupAt,
    this.hasLocalBackup = false,
    this.hasGdriveBackup = false,
    this.localFileExists = false,
  });

  final DateTime? lastBackupAt;
  final bool hasLocalBackup;
  final bool hasGdriveBackup;
  final bool localFileExists;
}
