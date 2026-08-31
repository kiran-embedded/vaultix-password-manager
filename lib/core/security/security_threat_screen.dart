import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class SecurityThreatScreen extends StatelessWidget {
  final String threatMessage;

  const SecurityThreatScreen({super.key, required this.threatMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        
    // Use the uniform app theme backgrounds
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return PopScope(
      canPop: false, // Prevent user from escaping this screen
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Standard Vaultix Background glow 
            Positioned.fill(
              child: CustomPaint(
                painter: _BackgroundPainter(isDark: isDark),
              ),
            ),
            
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Warning Icon (Uniform styling, but red to indicate error)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentRed.withOpacity(0.5), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.gpp_bad_rounded,
                          color: AppColors.accentRed,
                          size: 72,
                        ),
                      ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 32),
                      
                      Text(
                        'Security Alert',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: headerTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1),

                      const SizedBox(height: 16),
                      
                      GlassmorphicContainer(
                        width: double.infinity,
                        height: 160,
                        borderRadius: 24,
                        blur: 15,
                        alignment: Alignment.center,
                        border: 1,
                        linearGradient: LinearGradient(
                          colors: [
                            isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                            isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          colors: [
                            AppColors.accentRed.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'A critical security issue was detected on this device:',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(color: subtitleColor),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                threatMessage,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.headingSmall.copyWith(color: AppColors.accentRed, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1),
                      
                      const SizedBox(height: 40),

                      Text(
                        'To protect your sensitive data, Vaultix has locked the application. Please ensure your device environment is secure.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(color: subtitleColor, height: 1.5),
                      ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                      
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => SystemNavigator.pop(),
                          icon: Icon(Icons.exit_to_app_rounded, color: headerTextColor, size: 20),
                          label: Text(
                            'Exit Application',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: headerTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.black12,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Uniform background painter matching Vaultix style
class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final purpleGlow =
        isDark ? const Color(0x306338F6) : const Color(0x156338F6);
    final cyanGlow =
        isDark ? const Color(0x2036D7FF) : const Color(0x0A36D7FF);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15),
      160,
      Paint()
        ..shader = RadialGradient(
          colors: [purpleGlow, Colors.transparent],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.2, size.height * 0.15),
          radius: 160,
        )),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.75),
      120,
      Paint()
        ..shader = RadialGradient(
          colors: [cyanGlow, Colors.transparent],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.75),
          radius: 120,
        )),
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.isDark != isDark;
}
