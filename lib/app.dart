// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'router/app_router.dart';

/// Root application widget with auto-lock lifecycle and inactivity listeners.
class VaultixApp extends ConsumerStatefulWidget {
  const VaultixApp({super.key});

  @override
  ConsumerState<VaultixApp> createState() => _VaultixAppState();
}

class _VaultixAppState extends ConsumerState<VaultixApp> with WidgetsBindingObserver {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // If we resumed and the vault is unlocked, reset the inactivity timer
      final auth = ref.read(authStateProvider);
      if (auth.status == AuthStatus.unlocked) {
        _resetInactivityTimer();
      }
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    
    final auth = ref.read(authStateProvider);
    if (auth.status == AuthStatus.unlocked) {
      // Auto-lock after 1 minute of inactivity
      _inactivityTimer = Timer(const Duration(minutes: 1), () {
        ref.read(authStateProvider.notifier).lock();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    // Watch auth status changes to kick off inactivity timers
    ref.listen(authStateProvider, (prev, next) {
      _resetInactivityTimer();
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      child: MaterialApp.router(
        title: 'Vaultix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
