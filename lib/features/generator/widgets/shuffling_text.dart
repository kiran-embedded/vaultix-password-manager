// lib/features/generator/widgets/shuffling_text.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// A premium animated text widget that shuffles characters (like a decryption matrix)
/// and resolves to the final text from left to right.
class ShufflingText extends StatefulWidget {
  const ShufflingText({
    super.key,
    required this.text,
    required this.style,
  });

  final String text;
  final TextStyle style;

  @override
  State<ShufflingText> createState() => _ShufflingTextState();
}

class _ShufflingTextState extends State<ShufflingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late String _displayText;
  late String _targetText;
  final _random = Random();

  static const _scrambleChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()_+=-[]{}|;:,.<>?';

  @override
  void initState() {
    super.initState();
    _targetText = widget.text;
    _displayText = widget.text;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _controller.addListener(_updateShuffleText);
  }

  @override
  void didUpdateWidget(ShufflingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _targetText = widget.text;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateShuffleText() {
    final progress = _controller.value;
    if (progress == 1.0) {
      setState(() {
        _displayText = _targetText;
      });
      return;
    }

    final len = _targetText.length;
    final buffer = StringBuffer();

    for (int i = 0; i < len; i++) {
      // Determine if this specific character is resolved yet
      // Left-to-right sweep threshold
      final threshold = i / len;
      if (progress >= threshold) {
        buffer.write(_targetText[i]);
      } else {
        // Scramble with a random key symbol
        final charIndex = _random.nextInt(_scrambleChars.length);
        buffer.write(_scrambleChars[charIndex]);
      }
    }

    setState(() {
      _displayText = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
