// lib/core/utils/logo_utils.dart
import 'package:flutter/material.dart';

class BrandLogoInfo {
  final String name;
  final Color brandColor;
  final IconData fallbackIcon;
  final String? logoUrl;

  const BrandLogoInfo({
    required this.name,
    required this.brandColor,
    required this.fallbackIcon,
    this.logoUrl,
  });
}

abstract class LogoUtils {
  // Map of popular services to their details
  static const Map<String, BrandLogoInfo> _brandMap = {
    'google': BrandLogoInfo(
      name: 'Google',
      brandColor: Color(0xFF4285F4),
      fallbackIcon: Icons.g_mobiledata_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=google.com',
    ),
    'instagram': BrandLogoInfo(
      name: 'Instagram',
      brandColor: Color(0xFFE1306C),
      fallbackIcon: Icons.camera_alt_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=instagram.com',
    ),
    'twitter': BrandLogoInfo(
      name: 'Twitter',
      brandColor: Color(0xFF1DA1F2),
      fallbackIcon: Icons.alternate_email_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=twitter.com',
    ),
    'x.com': BrandLogoInfo(
      name: 'X',
      brandColor: Color(0xFF000000),
      fallbackIcon: Icons.close_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=x.com',
    ),
    'facebook': BrandLogoInfo(
      name: 'Facebook',
      brandColor: Color(0xFF1877F2),
      fallbackIcon: Icons.facebook_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=facebook.com',
    ),
    'netflix': BrandLogoInfo(
      name: 'Netflix',
      brandColor: Color(0xFFE50914),
      fallbackIcon: Icons.movie_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=netflix.com',
    ),
    'spotify': BrandLogoInfo(
      name: 'Spotify',
      brandColor: Color(0xFF1DB954),
      fallbackIcon: Icons.music_note_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=spotify.com',
    ),
    'amazon': BrandLogoInfo(
      name: 'Amazon',
      brandColor: Color(0xFFFF9900),
      fallbackIcon: Icons.shopping_bag_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=amazon.com',
    ),
    'github': BrandLogoInfo(
      name: 'GitHub',
      brandColor: Color(0xFF24292E),
      fallbackIcon: Icons.code_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=github.com',
    ),
    'dribbble': BrandLogoInfo(
      name: 'Dribbble',
      brandColor: Color(0xFFEA4C89),
      fallbackIcon: Icons.brush_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=dribbble.com',
    ),
    'linkedin': BrandLogoInfo(
      name: 'LinkedIn',
      brandColor: Color(0xFF0A66C2),
      fallbackIcon: Icons.work_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=linkedin.com',
    ),
    'apple': BrandLogoInfo(
      name: 'Apple',
      brandColor: Color(0xFFA2AAAD),
      fallbackIcon: Icons.apple_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=apple.com',
    ),
    'microsoft': BrandLogoInfo(
      name: 'Microsoft',
      brandColor: Color(0xFFF25022),
      fallbackIcon: Icons.window_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=microsoft.com',
    ),
    'reddit': BrandLogoInfo(
      name: 'Reddit',
      brandColor: Color(0xFFFF4500),
      fallbackIcon: Icons.reddit_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=reddit.com',
    ),
    'pinterest': BrandLogoInfo(
      name: 'Pinterest',
      brandColor: Color(0xFFBD081C),
      fallbackIcon: Icons.pin_drop_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=pinterest.com',
    ),
    'flipkart': BrandLogoInfo(
      name: 'Flipkart',
      brandColor: Color(0xFF2874F0),
      fallbackIcon: Icons.shopping_cart_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=flipkart.com',
    ),
    'kerala vision': BrandLogoInfo(
      name: 'Kerala Vision',
      brandColor: Color(0xFFE91E63),
      fallbackIcon: Icons.wifi_rounded,
      logoUrl: 'https://logo.clearbit.com/keralavisionbroadband.com',
    ),
    'hdfc': BrandLogoInfo(
      name: 'HDFC Bank',
      brandColor: Color(0xFF004C8F),
      fallbackIcon: Icons.account_balance_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=hdfcbank.com',
    ),
    'sbi': BrandLogoInfo(
      name: 'SBI Bank',
      brandColor: Color(0xFF0078D7),
      fallbackIcon: Icons.account_balance_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=onlinesbi.sbi',
    ),
    'icici': BrandLogoInfo(
      name: 'ICICI Bank',
      brandColor: Color(0xFFED3237),
      fallbackIcon: Icons.account_balance_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=icicibank.com',
    ),
    'axis': BrandLogoInfo(
      name: 'Axis Bank',
      brandColor: Color(0xFF8C2638),
      fallbackIcon: Icons.account_balance_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=axisbank.com',
    ),
    'federal bank': BrandLogoInfo(
      name: 'Federal Bank',
      brandColor: Color(0xFF0C2B58),
      fallbackIcon: Icons.account_balance_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=federalbank.co.in',
    ),
    'visa': BrandLogoInfo(
      name: 'Visa',
      brandColor: Color(0xFF1434CB),
      fallbackIcon: Icons.credit_card_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=visa.com',
    ),
    'mastercard': BrandLogoInfo(
      name: 'Mastercard',
      brandColor: Color(0xFFFF5F00),
      fallbackIcon: Icons.credit_card_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=mastercard.com',
    ),
    'rupay': BrandLogoInfo(
      name: 'RuPay',
      brandColor: Color(0xFF2870B8),
      fallbackIcon: Icons.credit_card_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=rupay.co.in',
    ),
    'jio': BrandLogoInfo(
      name: 'Jio',
      brandColor: Color(0xFFE31837),
      fallbackIcon: Icons.wifi_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=jio.com',
    ),
    'airtel': BrandLogoInfo(
      name: 'Airtel',
      brandColor: Color(0xFFFF0000),
      fallbackIcon: Icons.wifi_rounded,
      logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=airtel.in',
    ),
  };

  /// Detects brand info from a query title or website string
  static BrandLogoInfo detect(String query) {
    final lower = query.toLowerCase();

    for (final entry in _brandMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try to construct a favicon URL from a generic domain name
    if (lower.contains('.') && !lower.contains(' ')) {
      final domain = _extractDomain(lower);
      return BrandLogoInfo(
        name: query,
        brandColor: const Color(0xFF7C4DFF), // Default purple
        fallbackIcon: Icons.language_rounded,
        logoUrl: 'https://www.google.com/s2/favicons?sz=128&domain=$domain',
      );
    }

    // Ultimate generic fallback
    return BrandLogoInfo(
      name: query,
      brandColor: const Color(0xFF7C4DFF),
      fallbackIcon: Icons.lock_rounded,
      logoUrl: null,
    );
  }

  static String _extractDomain(String url) {
    String clean = url.trim().toLowerCase();
    if (clean.startsWith('http://')) clean = clean.substring(7);
    if (clean.startsWith('https://')) clean = clean.substring(8);
    if (clean.startsWith('www.')) clean = clean.substring(4);
    final slashIndex = clean.indexOf('/');
    if (slashIndex != -1) {
      clean = clean.substring(0, slashIndex);
    }
    return clean;
  }
}
