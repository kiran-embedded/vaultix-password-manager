// lib/core/services/local_backup_service.dart
import '../../features/vault/models/password_entry.dart';
import 'unified_backup_service.dart';

/// Thin wrapper — delegates to [UnifiedBackupService].
class LocalBackupService {
  LocalBackupService._();
  static final instance = LocalBackupService._();

  Future<bool> requestPermissions() =>
      UnifiedBackupService.instance.requestPermissions();

  Future<bool> hasLocalBackup() =>
      UnifiedBackupService.instance.hasLocalBackup();

  Future<void> performAutoBackup(List<PasswordEntry> entries) async {
    await UnifiedBackupService.instance.performBackup(entries: entries);
  }

  Future<bool> restoreFromLocalBackup(String masterPassword) =>
      UnifiedBackupService.instance.restoreFromLocalBackup(masterPassword);
}
