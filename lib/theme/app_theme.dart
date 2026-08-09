import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// پالت رنگی «معمار» - نسخه‌ی ارتقایافته با عمق بصری بیشتر:
/// پس‌زمینه‌ی تیره‌ی نزدیک به مشکی، لهجه‌ی طلایی/کهربایی (پیشرفت)، و یک
/// لهجه‌ی دوم آبی-فیروزه‌ای (الهام از نقشه‌های معماری/blueprint) برای
/// نمودارها و جزئیات ثانویه تا فضای بصری یک‌دست و کسل‌کننده نباشد.
class AppColors {
  static const background = Color(0xFF0A0B0D);
  static const surface = Color(0xFF16181D);
  static const surfaceLight = Color(0xFF212429);
  static const surfaceElevated = Color(0xFF272A31);

  static const primary = Color(0xFFE5AC4E); // طلایی کهربایی
  static const primaryDim = Color(0xFFB9863A);
  static const blueprint = Color(0xFF4FA3D1); // آبی بلوپرینت - لهجه‌ی دوم
  static const success = Color(0xFF4FC08D);
  static const danger = Color(0xFFE8604C);
  static const warning = Color(0xFFEBB33E);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF9A9CA8);
  static const textMuted = Color(0xFF64666F);

  static const cardBorder = Color(0x14FFFFFF); // حاشیه‌ی خیلی ظریف برای عمق

  static const heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF241C10), Color(0xFF16181D)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0C070), Color(0xFFD69A3E)],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.blueprint,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceLight,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.cardBorder, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.primary : AppColors.textSecondary);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// یک کارت استاندارد با حاشیه‌ی ظریف و سایه‌ی نرم که در سرتاسر اپ استفاده
/// می‌شود تا همه‌ی صفحات یک زبان بصری یک‌دست داشته باشند.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? borderColor;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
