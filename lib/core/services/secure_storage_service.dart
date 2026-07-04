import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/vault/models/password_entry.dart';
import 'unified_backup_service.dart';

class SecureStorageService {
  SecureStorageService._();
  static final instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyEntries = 'vaultix_entries';

  /// Load all entries from secure storage.
  Future<List<PasswordEntry>> loadEntries() async {
    try {
      final jsonStr = await _storage.read(key: _keyEntries);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return [];
      }
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((item) => PasswordEntry.fromJson(item)).toList();
    } catch (e) {
      // Return empty list if there's any corruption or reading error
      return [];
    }
  }

  /// Save all entries to secure storage.
  Future<void> saveEntries(List<PasswordEntry> entries, {bool skipBackup = false}) async {
    try {
      final jsonStr = jsonEncode(entries.map((e) => e.toJson()).toList());
      await _storage.write(key: _keyEntries, value: jsonStr);
      if (!skipBackup) {
        UnifiedBackupService.instance.performBackup(entries: entries);
      }
    } catch (_) {
      // Handle or log error
    }
  }

  /// Clear all secure data.
  Future<void> clearAll() async {
    await _storage.delete(key: _keyEntries);
  }
}
