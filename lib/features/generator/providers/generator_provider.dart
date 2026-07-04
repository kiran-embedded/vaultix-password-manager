// lib/features/generator/providers/generator_provider.dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/utils/password_utils.dart';

class GeneratorState {
  final int length;
  final bool useUpper;
  final bool useLower;
  final bool useDigits;
  final bool useSymbols;
  final String generated;
  final bool justCopied;

  const GeneratorState({
    this.length = 20,
    this.useUpper = true,
    this.useLower = true,
    this.useDigits = true,
    this.useSymbols = true,
    this.generated = '',
    this.justCopied = false,
  });

  PasswordStrength get strength => PasswordUtils.analyzeStrength(generated);
  int get strengthScore => PasswordUtils.strengthScore(generated);

  GeneratorState copyWith({
    int? length,
    bool? useUpper,
    bool? useLower,
    bool? useDigits,
    bool? useSymbols,
    String? generated,
    bool? justCopied,
  }) {
    return GeneratorState(
      length: length ?? this.length,
      useUpper: useUpper ?? this.useUpper,
      useLower: useLower ?? this.useLower,
      useDigits: useDigits ?? this.useDigits,
      useSymbols: useSymbols ?? this.useSymbols,
      generated: generated ?? this.generated,
      justCopied: justCopied ?? this.justCopied,
    );
  }
}

class GeneratorNotifier extends StateNotifier<GeneratorState> {
  GeneratorNotifier() : super(const GeneratorState()) {
    generate(); // auto-generate on first load
  }

  void generate() {
    final pw = PasswordUtils.generate(
      length: state.length,
      useUpper: state.useUpper,
      useLower: state.useLower,
      useDigits: state.useDigits,
      useSymbols: state.useSymbols,
    );
    state = state.copyWith(generated: pw, justCopied: false);
  }

  void setLength(int length) {
    state = state.copyWith(length: length);
    generate();
  }

  void toggleUpper(bool v) { state = state.copyWith(useUpper: v); generate(); }
  void toggleLower(bool v) { state = state.copyWith(useLower: v); generate(); }
  void toggleDigits(bool v) { state = state.copyWith(useDigits: v); generate(); }
  void toggleSymbols(bool v) { state = state.copyWith(useSymbols: v); generate(); }

  void markCopied() async {
    state = state.copyWith(justCopied: true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) state = state.copyWith(justCopied: false);
  }
}

final generatorProvider =
    StateNotifierProvider<GeneratorNotifier, GeneratorState>(
  (ref) => GeneratorNotifier(),
);
