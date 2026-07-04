// lib/vault/models/password_entry.dart

import 'package:flutter/material.dart';

/// Category of a vault entry.
enum EntryCategory {
  login,
  card,
  note,
  identity,
  wifi,
}

extension EntryCategoryX on EntryCategory {
  String get label => switch (this) {
        EntryCategory.login => 'Login',
        EntryCategory.card => 'Card',
        EntryCategory.note => 'Note',
        EntryCategory.identity => 'Identity',
        EntryCategory.wifi => 'Wi-Fi',
      };

  IconData get icon => switch (this) {
        EntryCategory.login => Icons.lock_rounded,
        EntryCategory.card => Icons.credit_card_rounded,
        EntryCategory.note => Icons.sticky_note_2_rounded,
        EntryCategory.identity => Icons.badge_rounded,
        EntryCategory.wifi => Icons.wifi_rounded,
      };
}

/// A single vault entry (password, card, note, etc.).
class PasswordEntry {
  final String id;
  final String title;
  final String username;
  final String password;
  final String? website;
  final String? notes;
  final EntryCategory category;
  final bool isFavorite;
  final Color brandColor;
  /// Stored as raw codePoint (int) so the release build can tree-shake icons.
  final int? customIconCodePoint;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Reconstructs the [IconData] only when needed in the UI layer.
  IconData? get customIcon => customIconCodePoint != null
      ? IconData(customIconCodePoint!, fontFamily: 'MaterialIcons')
      : null;

  const PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.website,
    this.notes,
    this.category = EntryCategory.login,
    this.isFavorite = false,
    this.brandColor = const Color(0xFF7C4DFF),
    this.customIconCodePoint,
    required this.createdAt,
    required this.updatedAt,
  });

  PasswordEntry copyWith({
    String? title,
    String? username,
    String? password,
    String? website,
    String? notes,
    EntryCategory? category,
    bool? isFavorite,
    Color? brandColor,
    int? customIconCodePoint,
  }) {
    return PasswordEntry(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      brandColor: brandColor ?? this.brandColor,
      customIconCodePoint: customIconCodePoint ?? this.customIconCodePoint,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasswordEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'website': website,
      'notes': notes,
      'category': category.index,
      'isFavorite': isFavorite,
      'brandColor': brandColor.value,
      'customIcon': customIconCodePoint,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      category: EntryCategory.values[json['category'] as int],
      isFavorite: json['isFavorite'] as bool? ?? false,
      brandColor: Color(json['brandColor'] as int),
      customIconCodePoint: json['customIcon'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
