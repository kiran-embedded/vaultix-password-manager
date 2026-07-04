// lib/shared/providers/tab_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Global active tab index provider for PageView-based shell navigation.
final tabIndexProvider = StateProvider<int>((ref) => 0);

/// Coordinates search input autofocus when navigation is triggered from outside the Vault tab.
final searchFocusProvider = StateProvider<bool>((ref) => false);
