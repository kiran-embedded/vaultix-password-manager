// lib/core/services/backup_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:crypto/crypto.dart';
import '../../features/vault/models/password_entry.dart';
import 'unified_backup_service.dart';

class BackupService {
  BackupService._();
  static final instance = BackupService._();

  enc.Key _deriveKey(String masterPassword) {
    // Generate a 256-bit key using SHA-256 hash of the master password
    final bytes = utf8.encode(masterPassword);
    final hashBytes = sha256.convert(bytes).bytes;
    return enc.Key(Uint8List.fromList(hashBytes));
  }

  /// Encrypts the vault entries list using AES-256-CBC.
  /// Returns a self-contained string format: "base64(iv):base64(ciphertext)"
  String encryptVault(List<PasswordEntry> entries, String masterPassword) {
    try {
      final key = _deriveKey(masterPassword);
      final iv = enc.IV.fromSecureRandom(16);
      
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final jsonStr = jsonEncode(entries.map((e) => e.toJson()).toList());
      final encrypted = encrypter.encrypt(jsonStr, iv: iv);
      
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Failed to encrypt vault entries: $e');
    }
  }

  /// Decrypts backup data. Supports legacy vault-only arrays and full payloads.
  List<PasswordEntry> decryptVault(String backupData, String masterPassword) {
    return UnifiedBackupService.instance
        .decryptBackup(backupData, masterPassword)
        .entries;
  }
}
