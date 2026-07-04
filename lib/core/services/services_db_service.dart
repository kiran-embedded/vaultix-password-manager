// lib/core/services/services_db_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

/// Representation of a popular online service.
class PopularService {
  final String name;
  final String domain;

  const PopularService({required this.name, required this.domain});

  factory PopularService.fromJson(Map<String, dynamic> json) {
    return PopularService(
      name: json['name'] as String,
      domain: json['domain'] as String,
    );
  }
}

/// Thread-safe in-memory database lookup service for popular online services.
class ServicesDbService {
  ServicesDbService._();
  static final instance = ServicesDbService._();

  List<PopularService> _services = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Loads the popular services dataset from assets into memory.
  Future<void> init() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/database/popular_services.json');
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _services = decoded.map((e) => PopularService.fromJson(e)).toList();
      _loaded = true;
    } catch (_) {
      // Graceful fallback to empty list
    }
  }

  /// Instant search filter query.
  /// Returns a max of 10 items, prioritizing prefix matches (startsWith) over substring (contains).
  List<PopularService> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();

    final startsWithMatches = <PopularService>[];
    final containsMatches = <PopularService>[];

    for (final service in _services) {
      final nameLower = service.name.toLowerCase();
      final domainLower = service.domain.toLowerCase();

      if (nameLower.startsWith(q) || domainLower.startsWith(q)) {
        startsWithMatches.add(service);
      } else if (nameLower.contains(q) || domainLower.contains(q)) {
        containsMatches.add(service);
      }

      // Early break if we have enough direct matches to render in suggestions
      if (startsWithMatches.length >= 10) break;
    }

    final combined = [...startsWithMatches, ...containsMatches];
    return combined.take(8).toList(); // Return top 8 suggestions
  }
}
