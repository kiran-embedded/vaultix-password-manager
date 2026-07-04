import 'package:flutter/services.dart';

class SecureScreenService {
  SecureScreenService._();

  static const _channel = MethodChannel('com.kiranembedded.vaultix/haptics');

  /// Toggles screenshot blocking (FLAG_SECURE) on Android.
  static Future<void> setSecureMode(bool secure) async {
    try {
      await _channel.invokeMethod('setSecureMode', {'secure': secure});
    } catch (_) {
      // Fail silently if not implemented or on non-Android platform
    }
  }
}
