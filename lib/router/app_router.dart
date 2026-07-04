// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/setup_screen.dart';
import '../features/auth/screens/totp_setup_screen.dart';
import '../features/auth/screens/totp_verify_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/security/screens/security_screen.dart';
import '../features/vault/screens/add_item_screen.dart';
import '../features/settings/screens/help_centre_screen.dart';
import '../shared/screens/main_screen.dart';

/// Fade page transition factory.
Page<void> _fadePage(BuildContext ctx, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// Slide-up page transition for modal-style screens.
Page<void> _slideUpPage(BuildContext ctx, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) {
      final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 380),
  );
}

// ─── Router provider ──────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: authState.status == AuthStatus.needsSetup ? '/setup' : '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final status = authState.status;
      final location = state.matchedLocation;

      if (status == AuthStatus.needsSetup) {
        if (location != '/setup') return '/setup';
      } else if (status == AuthStatus.locked) {
        if (location != '/') return '/';
      } else if (status == AuthStatus.awaiting2FA) {
        if (location != '/totp-verify') return '/totp-verify';
      } else if (status == AuthStatus.unlocked) {
        if (location == '/' || location == '/setup' || location == '/totp-verify') return '/home';
      }
      return null;
    },
    routes: [
      // Lock screen / Biometric entry
      GoRoute(
        path: '/',
        pageBuilder: (ctx, state) => _fadePage(ctx, state, const SplashScreen()),
      ),

      // Master Password Setup screen
      GoRoute(
        path: '/setup',
        pageBuilder: (ctx, state) => _fadePage(ctx, state, const SetupScreen()),
      ),

      // Main swipable navigation tab shell
      GoRoute(
        path: '/home',
        pageBuilder: (ctx, state) => _fadePage(ctx, state, const MainScreen()),
      ),

      // Security dashboard (pushed from home drawer or card)
      GoRoute(
        path: '/security',
        pageBuilder: (ctx, state) => _slideUpPage(ctx, state, const SecurityScreen()),
      ),

      // Add item (modal style)
      GoRoute(
        path: '/add',
        pageBuilder: (ctx, state) => _slideUpPage(ctx, state, const AddItemScreen()),
      ),

      // 2FA Setup (push from settings)
      GoRoute(
        path: '/totp-setup',
        pageBuilder: (ctx, state) => _slideUpPage(ctx, state, const TotpSetupScreen()),
      ),

      // 2FA Verification (redirect from locked state)
      GoRoute(
        path: '/totp-verify',
        pageBuilder: (ctx, state) => _fadePage(ctx, state, const TotpVerifyScreen()),
      ),

      // Help Centre
      GoRoute(
        path: '/help',
        pageBuilder: (ctx, state) => _slideUpPage(ctx, state, const HelpCentreScreen()),
      ),
    ],
  );
});
