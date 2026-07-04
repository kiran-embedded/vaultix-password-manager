// lib/features/vault/screens/add_item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_utils.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../core/services/services_db_service.dart';
import '../providers/vault_provider.dart';
import '../models/password_entry.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../shared/providers/tab_provider.dart';
import '../../../core/services/secure_screen_service.dart';

/// Add/Edit vault entry form screen with category tabs.
class AddItemScreen extends HookConsumerWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCat = useState(EntryCategory.login);
    final titleCtrl = useTextEditingController();
    final usernameCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final websiteCtrl = useTextEditingController();
    final notesCtrl = useTextEditingController();
    final passwordVisible = useState(false);
    final strength = useState(PasswordStrength.none);
    final isSaving = useState(false);
    final isSuccess = useState(false);

    useEffect(() {
      SecureScreenService.setSecureMode(true);
      return () {
        final currentTab = ref.read(tabIndexProvider);
        SecureScreenService.setSecureMode(currentTab == 1 || currentTab == 2);
      };
    }, const []);

    // Focus nodes for keyboard navigation
    final usernameFocusNode = useFocusNode();

    // Local state for autocomplete suggestions
    final suggestions = useState<List<PopularService>>([]);

    // Clipboard suggestion state
    final clipboardText = useState<String?>(null);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    // Load clipboard contents on startup
    useEffect(() {
      Future<void> checkClipboard() async {
        try {
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          final text = data?.text?.trim();
          if (text != null && text.isNotEmpty) {
            final isEmail = text.contains('@') && text.contains('.');
            final isUrl = text.startsWith('http') ||
                text.contains('.com') ||
                text.contains('.org') ||
                text.contains('.net') ||
                text.contains('.co') ||
                text.contains('www.');
            if (isEmail || isUrl) {
              clipboardText.value = text;
            }
          }
        } catch (_) {}
      }
      checkClipboard();
      return null;
    }, []);

    useEffect(() {
      passwordCtrl.addListener(() {
        strength.value = PasswordUtils.analyzeStrength(passwordCtrl.text);
      });
      return null;
    }, []);

    // Listen to title changes to update search suggestions
    useEffect(() {
      void onTitleChanged() {
        final text = titleCtrl.text.trim();
        if (text.isEmpty) {
          suggestions.value = [];
        } else {
          final matches = ServicesDbService.instance.search(text);
          // Hide list if the input matches a suggestion exactly
          if (matches.length == 1 && matches.first.name.toLowerCase() == text.toLowerCase()) {
            suggestions.value = [];
          } else {
            suggestions.value = matches;
          }
        }
      }
      titleCtrl.addListener(onTitleChanged);
      return () => titleCtrl.removeListener(onTitleChanged);
    }, []);

    Future<void> save() async {
      if (titleCtrl.text.trim().isEmpty) return;
      isSaving.value = true;
      await HapticHelper.medium();
      
      ref.read(vaultProvider.notifier).addEntry(
            PasswordEntry(
              id: const Uuid().v4(),
              title: titleCtrl.text.trim(),
              username: usernameCtrl.text.trim(),
              password: passwordCtrl.text,
              website: websiteCtrl.text.trim().isEmpty ? null : websiteCtrl.text.trim(),
              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              category: selectedCat.value,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          
      isSaving.value = false;
      isSuccess.value = true;
      await HapticHelper.success();
      await Future.delayed(const Duration(milliseconds: 300));
      if (context.mounted) context.pop();
    }

    // Dynamic labels based on category
    String titleLabel = 'Title';
    String titleHint = 'Example: Google';
    String usernameLabel = 'Email / Username';
    String usernameHint = 'username@example.com';
    String passwordLabel = 'Password';
    String websiteLabel = 'Website / URL';
    String websiteHint = 'https://google.com';
    String notesLabel = 'Notes (Optional)';
    TextInputType usernameKeyboardType = TextInputType.emailAddress;
    TextInputType passwordKeyboardType = TextInputType.visiblePassword;

    switch (selectedCat.value) {
      case EntryCategory.card:
        titleLabel = 'Bank Name';
        titleHint = 'e.g. HDFC Visa';
        usernameLabel = 'Cardholder Name';
        usernameHint = 'Name on card';
        passwordLabel = 'Card Number';
        passwordKeyboardType = TextInputType.number;
        websiteLabel = 'Expiry Date';
        websiteHint = 'MM/YY';
        notesLabel = 'CVV / PIN (Optional)';
        usernameKeyboardType = TextInputType.name;
        break;
      case EntryCategory.wifi:
        titleLabel = 'Router / Location';
        titleHint = 'e.g. Home Wi-Fi';
        usernameLabel = 'Network Name (SSID)';
        usernameHint = 'Wi-Fi name';
        passwordLabel = 'Wi-Fi Password';
        websiteLabel = 'Security Type';
        websiteHint = 'WPA2, WEP, etc.';
        usernameKeyboardType = TextInputType.text;
        break;
      case EntryCategory.note:
        titleLabel = 'Note Title';
        titleHint = 'e.g. Secret Door Code';
        usernameLabel = 'Topic (Optional)';
        usernameHint = 'Topic / Category';
        passwordLabel = 'Secret Content';
        websiteLabel = 'Related Link (Optional)';
        websiteHint = 'https://...';
        usernameKeyboardType = TextInputType.text;
        break;
      default:
        break;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticHelper.light();
            context.pop();
          },
          child: Icon(Icons.arrow_back_rounded, color: headerTextColor),
        ),
        title: Text('Add New Item', style: TextStyle(color: headerTextColor)),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: save,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category Tabs ───────────────────────────────────
            _CategoryTabs(
              selected: selectedCat.value,
              onSelect: (cat) {
                HapticHelper.light();
                selectedCat.value = cat;
              },
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: AppConstants.spaceLg),

            // ── Clipboard Smart Paste Badge ────────────────────
            if (clipboardText.value != null) ...[
              GestureDetector(
                onTap: () {
                  HapticHelper.light();
                  final text = clipboardText.value!;
                  if (text.contains('@')) {
                    usernameCtrl.text = text;
                    usernameFocusNode.requestFocus();
                  } else {
                    websiteCtrl.text = text;
                  }
                  clipboardText.value = null; // hide banner after use
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withAlpha(50), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_returned_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Paste '${clipboardText.value!.length > 25 ? '${clipboardText.value!.substring(0, 22)}...' : clipboardText.value}' from clipboard",
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticHelper.light();
                          clipboardText.value = null;
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close_rounded, color: AppColors.primary, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: AppConstants.spaceMd),
            ],

            // ── Title field ─────────────────────────────────────
            _FormField(
              label: titleLabel,
              controller: titleCtrl,
              hint: titleHint,
              autofocus: true,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

            // ── Autocomplete Suggestions ───────────────────────
            if (suggestions.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: suggestions.value.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions.value[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        backgroundColor: cardBgColor,
                        side: BorderSide(color: borderColor, width: 0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        avatar: const Icon(
                          Icons.search_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          '${suggestion.name} (${suggestion.domain})',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: headerTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          HapticHelper.light();
                          titleCtrl.text = suggestion.name;
                          websiteCtrl.text = suggestion.domain;
                          suggestions.value = [];
                          usernameFocusNode.requestFocus(); // Focus Username field for next input
                        },
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spaceMd),

            // ── Username field ──────────────────────────────────
            _FormField(
              label: usernameLabel,
              controller: usernameCtrl,
              focusNode: usernameFocusNode,
              hint: usernameHint,
              keyboardType: usernameKeyboardType,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),

            const SizedBox(height: AppConstants.spaceMd),

            // ── Password field ──────────────────────────────────
            _PasswordField(
              label: passwordLabel,
              controller: passwordCtrl,
              visible: passwordVisible.value,
              keyboardType: passwordKeyboardType,
              showGenerator: selectedCat.value != EntryCategory.card,
              onToggleVisible: () {
                HapticHelper.light();
                passwordVisible.value = !passwordVisible.value;
              },
              strength: strength.value,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: AppConstants.spaceMd),

            // ── Website field ───────────────────────────────────
            _FormField(
              label: websiteLabel,
              controller: websiteCtrl,
              hint: websiteHint,
              keyboardType: TextInputType.url,
            ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.2),

            const SizedBox(height: AppConstants.spaceMd),

            // ── Category dropdown ───────────────────────────────
            _FormField(
              label: 'Category',
              controller: TextEditingController(text: selectedCat.value.label),
              hint: 'Select Category',
              readOnly: true,
              suffixIcon: Icons.keyboard_arrow_down_rounded,
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),

            const SizedBox(height: AppConstants.spaceMd),

            // ── Notes field ────────────────────────────────────
            _FormField(
              label: notesLabel,
              controller: notesCtrl,
              hint: 'Add a note...',
              maxLines: 3,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

            const SizedBox(height: AppConstants.spaceXl),

            // ── Save Button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSuccess.value
                    ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28)
                        .animate().scale(curve: Curves.elasticOut, duration: 400.ms)
                    : isSaving.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Save to Vault',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: AppConstants.spaceHuge),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelect});
  final EntryCategory selected;
  final ValueChanged<EntryCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: EntryCategory.values.map((cat) {
          final isSelected = cat == selected;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 16,
                      color: isSelected ? Colors.white : textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected ? Colors.white : textMuted,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
    this.suffixIcon,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;
  final IconData? suffixIcon;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: labelColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyLarge.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon != null
                ? Icon(
                    suffixIcon,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    size: 18,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.visible,
    required this.onToggleVisible,
    required this.strength,
    this.keyboardType,
    this.showGenerator = true,
  });

  final String label;
  final TextEditingController controller;
  final bool visible;
  final VoidCallback onToggleVisible;
  final PasswordStrength strength;
  final TextInputType? keyboardType;
  final bool showGenerator;

  Color get _strengthColor => switch (strength) {
        PasswordStrength.veryStrong => AppColors.accentGreen,
        PasswordStrength.strong => AppColors.accentGreen,
        PasswordStrength.medium => AppColors.accentOrange,
        PasswordStrength.weak || PasswordStrength.veryWeak => AppColors.accentRed,
        PasswordStrength.none => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final iconColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(color: labelColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !visible,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyLarge.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: '••••••••••••',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleVisible,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: iconColor,
                      size: 18,
                    ),
                  ),
                ),
                if (showGenerator)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticHelper.medium();
                      final pw = PasswordUtils.generate();
                      controller.text = pw;
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (strength != PasswordStrength.none) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: PasswordUtils.strengthScore(controller.text) / 100,
                  backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation(_strengthColor),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                strength.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: _strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
