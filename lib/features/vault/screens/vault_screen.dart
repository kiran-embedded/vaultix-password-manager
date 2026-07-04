// lib/features/vault/screens/vault_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptic_helper.dart';
import '../providers/vault_provider.dart';
import '../widgets/password_card.dart';
import '../widgets/category_chips.dart';
import '../../../shared/providers/tab_provider.dart';

enum _SortMode { az, za, newest, oldest, favorites }

const _sortLabels = {
  _SortMode.az: 'A → Z',
  _SortMode.za: 'Z → A',
  _SortMode.newest: 'Newest First',
  _SortMode.oldest: 'Oldest First',
  _SortMode.favorites: 'Favorites First',
};

const _sortIcons = {
  _SortMode.az: Icons.sort_by_alpha_rounded,
  _SortMode.za: Icons.sort_by_alpha_rounded,
  _SortMode.newest: Icons.schedule_rounded,
  _SortMode.oldest: Icons.history_rounded,
  _SortMode.favorites: Icons.favorite_rounded,
};

class VaultScreen extends HookConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider);
    final searchCtrl = useTextEditingController();
    final focusNode = useFocusNode();
    final sortMode = useState(_SortMode.newest);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final borderIconColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final fillSearchColor = isDark ? const Color(0xFF1E1D24) : const Color(0xFFF1F3FA);
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final shouldFocusSearch = ref.watch(searchFocusProvider);

    useEffect(() {
      if (shouldFocusSearch) {
        Future.microtask(() {
          focusNode.requestFocus();
          ref.read(searchFocusProvider.notifier).state = false;
        });
      }
      return null;
    }, [shouldFocusSearch]);

    useEffect(() {
      searchCtrl.addListener(() {
        ref.read(vaultProvider.notifier).setSearch(searchCtrl.text);
      });
      return null;
    }, []);

    // Apply sort on top of vault's filtered list
    final baseFiltered = vault.filtered;
    final sorted = [...baseFiltered];
    switch (sortMode.value) {
      case _SortMode.az:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case _SortMode.za:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case _SortMode.newest:
        sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case _SortMode.oldest:
        sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case _SortMode.favorites:
        sorted.sort((a, b) {
          if (a.isFavorite && !b.isFavorite) return -1;
          if (!a.isFavorite && b.isFavorite) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
    }

    void showFilterSheet() {
      HapticHelper.medium();
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _FilterSheet(
          current: sortMode.value,
          isDark: isDark,
          onSelect: (mode) {
            HapticHelper.light();
            sortMode.value = mode;
            Navigator.pop(ctx);
          },
        ),
      );
    }

    final activeFilter = sortMode.value != _SortMode.newest;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vault',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: headerTextColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  Row(
                    children: [
                      // Filter button
                      GestureDetector(
                        onTap: showFilterSheet,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activeFilter
                                ? AppColors.primary.withAlpha(20)
                                : (isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: activeFilter ? AppColors.primary.withAlpha(80) : borderIconColor,
                              width: activeFilter ? 1.5 : 0.8,
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: activeFilter ? AppColors.primary : subColor,
                            size: 20,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                    ],
                  ),
                ],
              ),
            ),

            // ── Active sort chip ─────────────────────────────────
            if (activeFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: GestureDetector(
                  onTap: () { sortMode.value = _SortMode.newest; HapticHelper.light(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_sortIcons[sortMode.value], color: AppColors.primary, size: 13),
                        const SizedBox(width: 5),
                        Text(_sortLabels[sortMode.value]!,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 5),
                        const Icon(Icons.close_rounded, color: AppColors.primary, size: 13),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),

            // ── Category Filter Chips ────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CategoryChips(
                selectedCategory: vault.selectedCategory,
                onSelect: (cat) => ref.read(vaultProvider.notifier).setCategory(cat),
              ),
            ).animate().fadeIn(delay: 100.ms),

            // ── Search Bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: TextField(
                controller: searchCtrl,
                focusNode: focusNode,
                style: AppTextStyles.bodyLarge.copyWith(color: headerTextColor),
                decoration: InputDecoration(
                  hintText: 'Search passwords, sites...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, size: 22),
                  fillColor: fillSearchColor,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                  suffixIcon: vault.searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () { searchCtrl.clear(); ref.read(vaultProvider.notifier).setSearch(''); },
                          child: Icon(Icons.close_rounded,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, size: 18),
                        )
                      : null,
                ),
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: -0.2),

            // ── Password List ────────────────────────────────────
            Expanded(
              child: sorted.isEmpty
                  ? _EmptyState()
                  : AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                        physics: const BouncingScrollPhysics(),
                        itemCount: sorted.length,
                        itemBuilder: (context, i) {
                          final entry = sorted[i];
                          return AnimationConfiguration.staggeredList(
                            position: i,
                            duration: const Duration(milliseconds: 340),
                            child: SlideAnimation(
                              verticalOffset: 16,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: PasswordCard(
                                    entry: entry,
                                    onFavTap: () => ref.read(vaultProvider.notifier).toggleFavorite(entry.id),
                                    onDelete: () => ref.read(vaultProvider.notifier).deleteEntry(entry.id),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { HapticHelper.medium(); context.push('/add'); },
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text('New Entry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.current, required this.isDark, required this.onSelect});
  final _SortMode current;
  final bool isDark;
  final void Function(_SortMode) onSelect;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF16151A) : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Text('Sort & Filter', style: AppTextStyles.headingSmall.copyWith(
                color: textColor, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 20),
          ..._SortMode.values.map((mode) {
            final isSelected = current == mode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelect(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withAlpha(15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary.withAlpha(60) : borderColor,
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(_sortIcons[mode]!,
                            color: isSelected ? AppColors.primary : subColor, size: 20),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(_sortLabels[mode]!,
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: isSelected ? AppColors.primary : textColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final iconColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: iconColor.withAlpha(80), size: 72),
          const SizedBox(height: 18),
          Text('Your vault is empty', style: AppTextStyles.headingSmall.copyWith(color: primaryText)),
          const SizedBox(height: 8),
          Text('Tap New Entry to add your first password',
              style: AppTextStyles.bodyMedium.copyWith(color: secondaryText)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
