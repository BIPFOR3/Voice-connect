import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

// ==========================================
// 1. PRIMITIVOS (COLORES, ESPACIADOS, RADIOS)
// ==========================================

class AppColors {
  // Primitivos Primary
  static const primary50 = Color(0xFFE9ECFF);
  static const primary100 = Color(0xFFC8CFFD);
  static const primary200 = Color(0xFFA1B0FC);
  static const primary300 = Color(0xFF7690FC);
  static const primary400 = Color(0xFF5075FA);
  static const primary500 = Color(0xFF1D5BF7); // BASE
  static const primary600 = Color(0xFF1552EB);
  static const primary700 = Color(0xFF0046DE);
  static const primary800 = Color(0xFF003BD3);
  static const primary900 = Color(0xFF0024C2);

  // Primitivos Secondary
  static const secondary50 = Color(0xFFDDF6FD);
  static const secondary100 = Color(0xFFADE7FA);
  static const secondary200 = Color(0xFF71D7F9);
  static const secondary300 = Color(0xFF1EC7F7);
  static const secondary400 = Color(0xFF00BCF9);
  static const secondary500 = Color(0xFF02AFF8); // BASE
  static const secondary600 = Color(0xFF00A1E9);
  static const secondary700 = Color(0xFF038DD7);
  static const secondary800 = Color(0xFF027DC4);
  static const secondary900 = Color(0xFF015CA3);

  // Primitivos Feedback / Success
  static const success50 = Color(0xFFE5F7E8);
  static const success100 = Color(0xFFC3E8C6);
  static const success200 = Color(0xFF9CDAA3);
  static const success300 = Color(0xFF71CB7F);
  static const success400 = Color(0xFF4FC163);
  static const success500 = Color(0xFF25B645);
  static const success600 = Color(0xFF1BA53D);
  static const success700 = Color(0xFF019331);
  static const success800 = Color(0xFF058227);
  static const success900 = Color(0xFF058227);

  // Primitivos Feedback / Error
  static const error50 = Color(0xFFFFE9EC);
  static const error100 = Color(0xFFFFC9D0);
  static const error200 = Color(0xFFF29595);
  static const error300 = Color(0xFFEB696B);
  static const error400 = Color(0xFFF44345);
  static const error500 = Color(0xFFF82E26);
  static const error600 = Color(0xFFEA1F26);
  static const error700 = Color(0xFFD80F21);
  static const error800 = Color(0xFFCC0119);
  static const error900 = Color(0xFFBD000B);

  // Primitivos Feedback / Warning
  static const warning50 = Color(0xFFFFF9E2);
  static const warning100 = Color(0xFFFFEDB5);
  static const warning200 = Color(0xFFFFE284);
  static const warning300 = Color(0xFFFFD852);
  static const warning400 = Color(0xFFFFCD2C);
  static const warning500 = Color(0xFFFFC512);
  static const warning600 = Color(0xFFFFB60D);
  static const warning700 = Color(0xFFFFA306);
  static const warning800 = Color(0xFFFF9305);
  static const warning900 = Color(0xFFFF7305);

  // Primitivos Neutros
  static const gs50 = Color(0xFFFFFFFF);
  static const gs100 = Color(0xFFFAFAFA);
  static const gs200 = Color(0xFFF5F5F5);
  static const gs300 = Color(0xFFF0F0F0);
  static const gs400 = Color(0xFFDEDEDE);
  static const gs500 = Color(0xFFC2C2C2);
  static const gs600 = Color(0xFF979797);
  static const gs700 = Color(0xFF818181);
  static const gs800 = Color(0xFF606060);
  static const gs900 = Color(0xFF3C3C3C);
  static const gs1000 = Color(0xFF000000);
}

class AppSpacing {
  static const double spacing50 = 2;
  static const double spacing100 = 4;
  static const double spacing200 = 8;
  static const double spacing300 = 12;
  static const double spacing400 = 16;
  static const double spacing500 = 20;
  static const double spacing600 = 24;
  static const double spacing700 = 32;
  static const double spacing800 = 40;
  static const double spacing900 = 48;
}

class AppSizes {
  static const double zero = 0;
  static const double hairlineGap = 2;
  static const double indicatorHeight = 6;

  static const double backButton = 28;
  static const double playButton = 44;
  static const double controlButton = 48;
  static const double primaryControlButton = 68;
  static const double micFab = 72;

  static const double waveformWidth = 6;
  static const double waveformHeight = 48;
  static const double timerFontSize = 64;

  static const double micFabBottomOffset = 96;
  static const double bottomNavigationReservedSpace = 140;

  static const double profileAvatar = 152;
  static const double profileCameraButton = 42;
  static const double profileFieldHeight = 61;
  static const double profileHeaderTopGap = 52;
}

class AppIconSizes {
  static const double xs = 20;
  static const double sm = 22;
  static const double md = 24;
  static const double lg = 26;
  static const double xl = 28;
  static const double xxl = 32;
  static const double mic = 34;
}

class AppStroke {
  static const double hairline = 0.5;
  static const double thin = 1.5;
  static const double medium = 1.8;
}

class AppRadius {
  static const double none = 0;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 34;
  static const double xxl = 56;
  static const double radius = 9999;
}

class AppPadding {
  static const double xs = AppSpacing.spacing100;
  static const double sm = AppSpacing.spacing200;
  static const double md = AppSpacing.spacing400;
  static const double lg = AppSpacing.spacing600;
  static const double xl = AppSpacing.spacing800;
}

class AppMargin {
  static const double xs = AppSpacing.spacing100;
  static const double sm = AppSpacing.spacing200;
  static const double md = AppSpacing.spacing400;
  static const double lg = AppSpacing.spacing600;
  static const double xl = AppSpacing.spacing800;
}

class AppGap {
  static const double tight = AppSpacing.spacing100;
  static const double related = AppSpacing.spacing200;
  static const double component = AppSpacing.spacing400;
  static const double group = AppSpacing.spacing600;
  static const double section = AppSpacing.spacing800;
}

// ==========================================
// 2. ELEVACIONES Y TIPOGRAFÍA
// ==========================================

class AppElevations {
  static const BoxShadow level1 = BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 1),
    blurRadius: 2,
  );
  static const BoxShadow level2 = BoxShadow(
    color: Color(0x24000000),
    offset: Offset(0, 4),
    blurRadius: 8,
  );
  static const BoxShadow level3 = BoxShadow(
    color: Color(0x29000000),
    offset: Offset(0, 8),
    blurRadius: 16,
  );
  static const BoxShadow level4 = BoxShadow(
    color: Color(0x33000000),
    offset: Offset(0, 16),
    blurRadius: 32,
  );
}

class AppTypography {
  static const String fontFamily = 'DM Sans';

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 101,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.49,
    color: AppColors.gs1000,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 63,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.79,
    color: AppColors.gs1000,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 50,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.gs1000,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.69,
    color: AppColors.gs1000,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 25,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.gs1000,
  );

  static const TextStyle h6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 21,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.71,
    color: AppColors.gs1000,
  );

  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.88,
    color: AppColors.gs1000,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.67,
    color: AppColors.gs1000,
  );

  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 2.94,
    color: AppColors.gs1000,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.67,
    color: AppColors.gs1000,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 8.33,
    color: AppColors.gs50,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 3.08,
    color: AppColors.gs1000,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 15,
    color: AppColors.gs1000,
  );
}

const TextTheme appTextTheme = TextTheme(
  displayLarge: AppTypography.h1,
  displayMedium: AppTypography.h2,
  displaySmall: AppTypography.h3,

  headlineLarge: AppTypography.h4,
  headlineMedium: AppTypography.h5,
  headlineSmall: AppTypography.h6,

  titleLarge: AppTypography.subtitle1,
  titleMedium: AppTypography.subtitle2,
  // titleSmall: AppTypography.subtit,

  bodyLarge: AppTypography.body1,
  bodyMedium: AppTypography.body2,
  bodySmall: AppTypography.caption,

  labelLarge: AppTypography.button,
  //labelMedium: AppTypography.label,
  labelSmall: AppTypography.overline,
);

// ==========================================
// 3. SEMÁNTICA
// ==========================================

class AppSemanticColors {
  // Primary
  static const Color primary = AppColors.primary500;
  static const Color primaryHover = AppColors.primary700;
  static const Color primaryPressed = AppColors.primary900;
  static const Color primaryDisabled = AppColors.primary100;
  static const Color onPrimaryDisabled = AppColors.primary200;
  static const Color onPrimary = AppColors.gs50;

  // Primary Container
  static const Color primaryContainer = AppColors.primary50;
  static const Color primaryContainerHover = AppColors.primary100;
  static const Color primaryContainerPressed = AppColors.primary200;
  static const Color onPrimaryContainer = AppColors.primary500;

  // Secondary
  static const Color secondary = AppColors.secondary200;
  static const Color secondaryHover = AppColors.secondary400;
  static const Color secondaryPressed = AppColors.secondary600;
  static const Color secondaryDisabled = AppColors.secondary100;
  static const Color onSecondary = AppColors.gs1000;

  // Secondary Container
  static const Color secondaryContainer = AppColors.secondary50;
  static const Color secondaryContainerHover = AppColors.secondary100;
  static const Color secondaryContainerPressed = AppColors.secondary200;
  static const Color onSecondaryContainer = AppColors.gs1000;

  // Surface
  static const Color surfaceMain = AppColors.gs50;
  static const Color onSurfaceMain = AppColors.gs1000;

  // Feedback
  static const Color error = AppColors.error500;
  static const Color onError = AppColors.gs50;
  static const Color success = AppColors.success500;
  static const Color onSuccess = AppColors.gs50;
  static const Color warning = AppColors.warning500;
  static const Color onWarning = AppColors.gs50;

  // Outline
  static const Color outline = AppColors.gs500;
}

// ==========================================
// 4. COMPONENTES
// ==========================================

class AppCardTokens {
  static const Color defaultBg = AppSemanticColors.surfaceMain;
  static const Color defaultIcon = AppSemanticColors.primaryDisabled;
  static const Color defaultLabel = AppSemanticColors.onPrimaryContainer;
  static const Color selectedBg = AppSemanticColors.primaryContainer;
  static const Color selectedIcon = AppSemanticColors.primary;
  static const Color selectedLabel = AppSemanticColors.onSecondary;
  static const Color disabledBg = AppColors.gs200;
  static const Color disabledIcon = AppColors.gs400;
  static const Color disabledLabel = AppColors.gs600;
  static const Color subtLabel = AppColors.gs600;
  static const double iconComm = 36.0;
  static const double iconSm = 32.5;
  static const double iconProfile = 18.0;
  static const double radiusSm = AppRadius.m;
}

class AppChipTokens {
  static const Color defaultBg = AppColors.gs50;
  static const Color defaultStroke = AppColors.gs1000;
  static const Color defaultLabel = AppColors.gs1000;
  static const Color activeBg = AppColors.primary500;
  static const Color activeLabel = AppColors.gs50;
  static const Color disabledBg = AppColors.gs300;
  static const Color disabledLabel = AppColors.gs400;
  static const Color disabledStroke = AppColors.gs400;
  static const double radiusSm = AppRadius.m;
}

class AppDialogTokens {
  static const Color defaultBg = Color(0xFFF9FAFF);
  static const Color defaultLabel = AppColors.primary500;
  static const Color defaultIcon = AppColors.primary500;
  static const Color defaultIconSuccess = AppSemanticColors.success;
  static const Color defaultText = AppColors.gs1000;
  static const Color defaultButton = AppColors.gs300;
  static const double radiusMd = AppRadius.xl;
}

class AppTabTokens {
  static const Color defaultBg = AppColors.gs400;
  static const Color defaultLabel = AppColors.gs1000;
  static const Color activeBg = AppSemanticColors.primary;
  static const Color defaultLabel2 = AppColors.gs1000;
  static const Color disabled = AppColors.gs300;
  static const Color disabledLabel = AppColors.gs600;
  static const double radiusXs = AppRadius.xs;
  static const double size = 144.0;
}

class AppBackdropTokens {
  static const Color defaultBg = Color(0xFFFFFFFF);
  static const Color disabledBg = AppColors.gs200;
  static const Color defaultLabel = AppColors.gs1000;
  static const Color disabledLabel = AppColors.gs500;
  static const Color defaultText = AppColors.gs1000;
  static const Color defaultSubtitle = AppColors.gs600;
  static const double radiusSm = AppRadius.m;
}

class AppOverflowMenuTokens {
  static const Color defaultBg = AppColors.gs50;
  static const Color selectedBg = AppColors.primary50;
  static const Color disabledBg = AppColors.gs200;
  static const Color defaultLabel = AppColors.gs1000;
  static const Color defaultIcon = AppColors.gs1000;
  static const Color disabledLabel = AppColors.gs500;
  static const Color disabledIcon = AppColors.gs500;
  static const double radiusSm = AppRadius.m;
  static const double iconSizeSm = 14.0;
}

class AppTextInputTokens {
  static const Color defaultBg = AppColors.gs300;
  static const Color strokeFocused = AppSemanticColors.primaryHover;
  static const Color strokeError = AppColors.error500;
  static const Color disabledBg = AppColors.gs200;
  static const Color iconStroke = AppColors.gs1000;
  static const Color iconStrokeDisabled = AppColors.gs500;
  static const Color label = AppColors.gs1000;
  static const Color holder = AppColors.gs600;
  static const Color holderDisabled = AppColors.gs400;
  static const double radiusSm = AppRadius.s;
  static const double radiusMd = AppRadius.m;
  static const double radiusXl = AppRadius.l;
  static const double iconSm = 22.0;
  static const double iconMd = 24.0;
  static const double iconXl = 26.0;
}

class AppButtonTokens {
  static const Color iconActive = AppSemanticColors.onPrimaryContainer;
  static const Color iconInactive = AppColors.gs600;
  static const Color iconDisabled = AppColors.gs300;
  static const Color filledBg = AppSemanticColors.primary;
  static const Color filledLabel = AppSemanticColors.onPrimary;
  static const Color filledDisabledBg = AppSemanticColors.primaryDisabled;
  static const Color filledLabelDisabled = AppSemanticColors.onPrimary;
  static const Color outlinedBg = AppSemanticColors.surfaceMain;
  static const Color outlinedStroke = AppSemanticColors.primary;
  static const Color outlinedLabel = AppSemanticColors.primary;
  static const Color outlinedStrokeDisabled = AppSemanticColors.primaryDisabled;
  static const Color outlinedLabelDisabled = AppSemanticColors.primaryDisabled;
  static const Color iconTextBg = AppSemanticColors.primary;
  static const Color iconTextLabel = AppSemanticColors.onPrimary;
  static const Color iconTextIcon = AppSemanticColors.primaryContainer;
}

class AppBottomNavTokens {
  static const Color defaultBg = AppColors.gs400;
  static const Color iconActive = AppColors.gs50;
  static const Color iconBg = AppColors.gs1000;
  static const Color iconStroke = AppColors.gs1000;
  static const Color iconDisabled = AppColors.gs500;
  static const Color iconDisabledStroke = AppColors.gs500;
  static const double iconSize = 20.0;
  static const double radiusSm = AppRadius.xl;
}

// ==========================================
// 5. CONFIGURACIÓN DEL TEMA (FlexColorScheme)
// ==========================================

abstract final class AppTheme {
  static ThemeData light = FlexThemeData.light(
    colors: const FlexSchemeColor(
      primary: AppSemanticColors.primary,
      primaryContainer: AppSemanticColors.primaryContainer,
      secondary: AppSemanticColors.secondary,
      secondaryContainer: AppSemanticColors.secondaryContainer,
      appBarColor: AppSemanticColors.surfaceMain,
      error: AppSemanticColors.error,
      errorContainer: AppColors.error500,
    ),
    textTheme: appTextTheme,
    primaryTextTheme: appTextTheme,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
  );
}
