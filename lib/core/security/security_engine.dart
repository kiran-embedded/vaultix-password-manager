import 'package:flutter/foundation.dart';
import 'package:freerasp/freerasp.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Provides the current active threat, or null if secure.
final securityThreatProvider = StateNotifierProvider<SecurityThreatNotifier, String?>(
  (ref) => SecurityThreatNotifier(),
);

class SecurityThreatNotifier extends StateNotifier<String?> {
  SecurityThreatNotifier() : super(null);

  void reportThreat(String threatMessage) {
    if (state == null) {
      state = threatMessage;
    }
  }

  void clearThreat() {
    state = null;
  }
}

class SecurityEngine {
  static Future<void> initialize(ProviderContainer container) async {
    // Only initialize in release/profile mode or specific testing environments
    // because emulators and debuggers will immediately trigger threats.
    // However, freeRASP supports an 'isDev' flag.
    
    // Create the Talsec configuration
    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.kiranembedded.vaultix',
        signingCertHashes: ['YOUR_BASE64_ENCODED_CERT_HASH'],
        supportedStores: ['com.sec.android.app.samsungapps'],
      ),
      iosConfig: IOSConfig(
        bundleIds: ['com.kiranembedded.vaultix'],
        teamId: 'YOUR_TEAM_ID',
      ),
      watcherMail: 'security@vaultix.com',
      isProd: kReleaseMode,
    );

    // Setup the callback listener
    final callback = ThreatCallback(
      onAppIntegrity: () => _report(container, 'App Integrity Compromised (Tampered / Modded APK)'),
      onObfuscationIssues: () => _report(container, 'App Obfuscation Issues Detected'),
      onDebug: () => _report(container, 'Debugging Mode Detected'),
      onDeviceBinding: () => _report(container, 'Device Binding / Cloned App Detected'),
      onDeviceID: () => _report(container, 'Device ID Spoofing Detected'),
      onHooks: () => _report(container, 'Hooking Framework (Magisk / Zygisk / Xposed) Detected'),
      onPasscode: () => _report(container, 'Device Passcode Not Set'),
      onPrivilegedAccess: () => _report(container, 'Privileged Access (Root / Jailbreak) Detected'),
      onSecureHardwareNotAvailable: () => _report(container, 'Secure Hardware Not Supported'),
      onSimulator: () => _report(container, 'Emulator or Simulator Detected'),
      onUnofficialStore: () => _report(container, 'App Installed from Unofficial Store / Play Integrity Failed'),
    );

    // Attach listener and start Talsec
    Talsec.instance.attachListener(callback);
    await Talsec.instance.start(config);
  }

  static void reportSimulatedThreat(WidgetRef ref, String message) {
    ref.read(securityThreatProvider.notifier).reportThreat(message);
  }

  static void _report(ProviderContainer container, String message) {
    // We only report if it's release mode to prevent blocking devs, 
    // OR if we want to enforce it always (user requested advanced security).
    // Let's enforce it strictly, but if it's debug mode, maybe we just log it so dev isn't impossible?
    // Actually, user said: "if user root but spooofed still the app detect root and deviece issue beautfdul screeen show"
    container.read(securityThreatProvider.notifier).reportThreat(message);
  }
}
