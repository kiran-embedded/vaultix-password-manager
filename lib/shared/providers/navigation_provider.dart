// lib/shared/providers/navigation_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Tracks the currently selected bottom nav index.
final navigationIndexProvider = StateProvider<int>((ref) => 0);
