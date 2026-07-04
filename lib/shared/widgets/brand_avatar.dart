// lib/shared/widgets/brand_avatar.dart
import 'package:flutter/material.dart';
import '../../features/vault/models/password_entry.dart';
import '../../core/utils/logo_utils.dart';

class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    required this.entry,
    this.size = 40.0,
  });

  final PasswordEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    // If a customIcon or brandColor was manually saved, respect it, otherwise auto-detect
    final String website = entry.website ?? '';
    final detected = LogoUtils.detect(website.isNotEmpty ? website : entry.title);
    final color = entry.brandColor != const Color(0xFF7C4DFF) ? entry.brandColor : detected.brandColor;
    final icon = entry.customIcon ?? detected.fallbackIcon;
    final logoUrl = detected.logoUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: color.withAlpha(50),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null
          ? Image.network(
              logoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(color, icon),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                );
              },
            )
          : _fallback(color, icon),
    );
  }

  Widget _fallback(Color color, IconData icon) {
    if (entry.title.isEmpty) {
      return Icon(icon, color: color, size: size * 0.52);
    }
    return Center(
      child: Text(
        entry.title[0].toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}
