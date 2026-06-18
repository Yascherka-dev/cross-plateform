import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Fonds & surfaces
  static const Color fond = Color(0xFFFBF8F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bordure = Color(0xFFF1EBE1);
  static const Color separateur = Color(0xFFF1ECE3);
  static const Color poignee = Color(0xFFE6DDD0);

  // Textes
  static const Color textePrincipal = Color(0xFF25201B);
  static const Color texteSecondaire = Color(0xFFA89C8D);
  static const Color texteTertiaire = Color(0xFFAEA395);
  static const Color texteSurface = Color(0xFF3E362D);
  static const Color iconeDiscrete = Color(0xFFC9BDAD);

  // Accent
  static const Color accent = Color(0xFFBC5038);

  // Spots fraîcheur
  static const Color parcTexte = Color(0xFF3E8266);
  static const Color parcFond = Color(0xFFE9F0EA);

  static const Color fontaineTexte = Color(0xFF5E89AC);
  static const Color fontaineFond = Color(0xFFEBF0F4);

  static const Color equipementTexte = Color(0xFF7B6CA8);
  static const Color equipementFond = Color(0xFFEEEBF3);

  // Risques
  static const Color vertTexte = Color(0xFF3E8266);
  static const Color vertFond = Color(0xFFE9F0EA);

  static const Color orangeTexte = Color(0xFFB57A24);
  static const Color orangeFond = Color(0xFFF4ECDB);

  static const Color rougeTexte = Color(0xFFC0392A);
  static const Color rougeFond = Color(0xFFF6E7E2);

  // Carte d'avertissement urgence
  static const Color urgenceTexte = Color(0xFF8A3322);
  static const Color urgenceBordure = Color(0xFFEFD9D0);

  // Statuts
  static const Color ouvertTexte = Color(0xFF3E8266);
  static const Color ouvertFond = Color(0xFFE9F0EA);

  static const Color fermeTexte = Color(0xFFBC4A33);
  static const Color fermeFond = Color(0xFFF6E7E2);

  // Rayons
  static const double radiusHero = 20;
  static const double radiusCarte = 16;
  static const double radiusCarteSmall = 14;
  static const double radiusPetit = 11;
  static const double radiusBadge = 999;

  // Espacements
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  static const double spacingXxl = 24;

  // Ombres
  static const List<BoxShadow> ombreBase = [
    BoxShadow(
      color: Color(0x0825201B),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> ombreImportante = [
    BoxShadow(
      color: Color(0x4025201B),
      blurRadius: 26,
      spreadRadius: -20,
      offset: Offset(0, 12),
    ),
  ];

  // Titres
  static TextStyle titre(double size) {
    return GoogleFonts.hankenGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: size * -0.02,
      color: textePrincipal,
      height: 1.08,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = texteSurface,
  }) {
    return GoogleFonts.hankenGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.35,
    );
  }

  static TextStyle label({
    double size = 12,
    Color color = texteSecondaire,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.hankenGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0.1,
    );
  }

  static TextStyle sectionLabel() {
    return GoogleFonts.hankenGrotesk(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: texteTertiaire,
      letterSpacing: 0.8,
    );
  }

  static ThemeData get theme {
    final baseTextTheme = GoogleFonts.hankenGroteskTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fond,
      fontFamily: GoogleFonts.hankenGrotesk().fontFamily,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: accent,
        secondary: fontaineTexte,
        tertiary: parcTexte,
        error: rougeTexte,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: textePrincipal,
      ),

      textTheme: baseTextTheme.copyWith(
        displayLarge: titre(34),
        displayMedium: titre(30),
        displaySmall: titre(26),
        headlineLarge: titre(24),
        headlineMedium: titre(22),
        headlineSmall: titre(20),
        titleLarge: titre(18),
        titleMedium: GoogleFonts.hankenGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: textePrincipal,
        ),
        titleSmall: GoogleFonts.hankenGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: textePrincipal,
        ),
        bodyLarge: body(size: 16),
        bodyMedium: body(size: 14),
        bodySmall: body(size: 12, color: texteSecondaire),
        labelLarge: label(size: 14, weight: FontWeight.w700),
        labelMedium: label(size: 12),
        labelSmall: label(size: 10.5, color: texteTertiaire),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: fond,
        foregroundColor: textePrincipal,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: titre(18),
        iconTheme: const IconThemeData(color: textePrincipal),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCarte),
          side: const BorderSide(color: bordure),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPetit),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: texteSurface,
          side: const BorderSide(color: bordure),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 13,
          ),
          textStyle: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPetit),
          ),
        ),
      ),

      iconTheme: const IconThemeData(
        color: texteSurface,
        size: 22,
      ),

      dividerTheme: const DividerThemeData(
        color: separateur,
        thickness: 1,
        space: 0,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: fond.withValues(alpha: 0.94),
        selectedItemColor: accent,
        unselectedItemColor: texteTertiaire,
        selectedLabelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: textePrincipal,
        disabledColor: separateur,
        side: const BorderSide(color: bordure),
        labelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: texteSurface,
        ),
        secondaryLabelStyle: GoogleFonts.hankenGrotesk(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusBadge),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: fond,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        titleTextStyle: titre(19),
        contentTextStyle: body(size: 13, color: texteSecondaire),
      ),
    );
  }
}