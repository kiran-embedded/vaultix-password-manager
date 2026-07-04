// lib/core/utils/haptic_helper.dart
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Unified haptic manager.
///
/// Mode 0 = Off
/// Mode 1 = Compatible  (vibration package — works on ALL Android devices)
/// Mode 2 = Flagship    (Flutter HapticFeedback + vibration fallback)
abstract class HapticHelper {
  /// Starts at 1 (Compatible) so Samsung A-series / budget phones work immediately.
  /// User can upgrade to 2 in Settings → Haptic Strength.
  static int hapticMode = 1;

  static Future<void> _vib(int ms, {int amplitude = 128}) async {
    try {
      await Vibration.vibrate(duration: ms, amplitude: amplitude);
    } catch (_) {}
  }

  /// Light — buttons, keyboard taps, list selection
  static Future<void> light() async {
    if (hapticMode == 0) return;
    if (hapticMode == 1) {
      await _vib(15, amplitude: 80);
    } else {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {
        await _vib(15, amplitude: 80);
      }
    }
  }

  /// Medium — toggles, chip selects, tab changes
  static Future<void> medium() async {
    if (hapticMode == 0) return;
    if (hapticMode == 1) {
      await _vib(22, amplitude: 128);
    } else {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {
        await _vib(22, amplitude: 128);
      }
    }
  }

  /// Heavy — destructive actions, delete
  static Future<void> heavy() async {
    if (hapticMode == 0) return;
    if (hapticMode == 1) {
      await _vib(45, amplitude: 200);
    } else {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {
        await _vib(45, amplitude: 200);
      }
    }
  }

  /// Selection — slider tick, scroll notch
  static Future<void> selection() async {
    if (hapticMode == 0) return;
    if (hapticMode == 1) {
      await _vib(10, amplitude: 60);
    } else {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {
        await _vib(10, amplitude: 60);
      }
    }
  }

  /// Success — double-tap confirmation (copy, unlock, save)
  static Future<void> success() async {
    if (hapticMode == 0) return;
    await _vib(15, amplitude: 100);
    await Future.delayed(const Duration(milliseconds: 60));
    await _vib(25, amplitude: 160);
  }

  /// Error — double heavy pulse (wrong password, delete fail)
  static Future<void> error() async {
    if (hapticMode == 0) return;
    await _vib(35, amplitude: 200);
    await Future.delayed(const Duration(milliseconds: 80));
    await _vib(35, amplitude: 200);
  }
}
