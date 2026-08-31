// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/services_db_service.dart';
import 'core/security/security_engine.dart';
import 'core/security/security_threat_screen.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the popular services database
  await ServicesDbService.instance.init();

  // Force AMOLED portrait with transparent system bars
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();

  // Create a shared ProviderContainer
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Initialize Advanced Security Engine (do not await to prevent blocking the initial frame)
  SecurityEngine.initialize(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const _VaultixRootApp(),
    ),
  );
}

class _VaultixRootApp extends ConsumerWidget {
  const _VaultixRootApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threatMessage = ref.watch(securityThreatProvider);
    
    if (threatMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Theme.of(context),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        home: SecurityThreatScreen(threatMessage: threatMessage),
      );
    }
    
    return const VaultixApp();
  }
}
