import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/password_entry.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/services/unified_backup_service.dart';
import '../../settings/providers/settings_provider.dart';

/// Demo seed data — in production this would be encrypted local storage.

// ─── State ────────────────────────────────────────────────────────────

class VaultState {
  final List<PasswordEntry> entries;
  final String searchQuery;
  final EntryCategory? selectedCategory;

  const VaultState({
    required this.entries,
    this.searchQuery = '',
    this.selectedCategory,
  });

  List<PasswordEntry> get filtered {
    var result = entries;
    if (selectedCategory != null) {
      result = result.where((e) => e.category == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.username.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  List<PasswordEntry> get favorites => entries.where((e) => e.isFavorite).toList();
  int get passwordCount => entries.where((e) => e.category == EntryCategory.login).length;
  int get noteCount => entries.where((e) => e.category == EntryCategory.note).length;
  int get cardCount => entries.where((e) => e.category == EntryCategory.card).length;
  int get idCount => entries.where((e) => e.category == EntryCategory.identity).length;

  VaultState copyWith({
    List<PasswordEntry>? entries,
    String? searchQuery,
    EntryCategory? selectedCategory,
    bool clearCategory = false,
  }) {
    return VaultState(
      entries: entries ?? this.entries,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────

class VaultNotifier extends StateNotifier<VaultState> {
  final Ref ref;

  VaultNotifier(this.ref) : super(const VaultState(entries: [])) {
    init();
  }

  Future<void> init() async {
    final stored = await SecureStorageService.instance.loadEntries();
    state = VaultState(entries: stored);
  }

  Future<void> _triggerAutoBackup(List<PasswordEntry> entries) async {
    await UnifiedBackupService.instance.performBackup(entries: entries);
    ref.read(settingsProvider.notifier).refreshBackupMetadata();
  }

  Future<void> addEntry(PasswordEntry entry) async {
    final updated = [...state.entries, entry];
    state = state.copyWith(entries: updated);
    await SecureStorageService.instance.saveEntries(updated);
    _triggerAutoBackup(updated);
  }

  Future<void> updateEntry(PasswordEntry entry) async {
    final updated = state.entries.map((e) => e.id == entry.id ? entry : e).toList();
    state = state.copyWith(entries: updated);
    await SecureStorageService.instance.saveEntries(updated);
    _triggerAutoBackup(updated);
  }

  Future<void> deleteEntry(String id) async {
    final updated = state.entries.where((e) => e.id != id).toList();
    state = state.copyWith(entries: updated);
    await SecureStorageService.instance.saveEntries(updated);
    _triggerAutoBackup(updated);
  }

  Future<void> toggleFavorite(String id) async {
    final updated = state.entries
        .map((e) => e.id == id ? e.copyWith(isFavorite: !e.isFavorite) : e)
        .toList();
    state = state.copyWith(entries: updated);
    await SecureStorageService.instance.saveEntries(updated);
    _triggerAutoBackup(updated);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(EntryCategory? cat) {
    if (cat == null || cat == state.selectedCategory) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: cat, clearCategory: false);
    }
  }

  Future<void> restoreEntries(List<PasswordEntry> newEntries) async {
    state = state.copyWith(entries: newEntries);
    await SecureStorageService.instance.saveEntries(newEntries);
    _triggerAutoBackup(newEntries);
  }

  Future<void> clearAll() async {
    state = state.copyWith(entries: []);
    await SecureStorageService.instance.saveEntries([]);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────

final vaultProvider =
    StateNotifierProvider<VaultNotifier, VaultState>((ref) => VaultNotifier(ref));
