import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neutres
  static const Color fondDsfr       = Color(0xFFF0F4FF);
  static const Color bordureDsfr    = Color(0xFFE5E7EB);
  static const Color titreDsfr      = Color(0xFF1A1A2E);
  static const Color griseTexteDsfr = Color(0xFF6B7280);
  static const Color bleuRepublique = Color(0xFF3B5BDB);

  // Niveaux de risque — fond pastel + texte/bordure saturé
  static const Color vertFond   = Color(0xFFD3F9D8);
  static const Color vertDsfr   = Color(0xFF2F9E44);
  static const Color orangeFond = Color(0xFFFFE8CC);
  static const Color orangeDsfr = Color(0xFFE67700);
  static const Color rougeFond  = Color(0xFFFFE3E3);
  static const Color rougeDsfr  = Color(0xFFC92A2A);

  // Urgences
  static const Color urgenceFond = Color(0xFFEDF2FF);

  // -------------------------
  // THÈME MATERIAL 3
  // -------------------------
  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: bleuRepublique,
      primary:   bleuRepublique,
      error:     rougeDsfr,
      surface:   Colors.white,
    ),

    // Inter via google_fonts (licence OFL) — remplace Marianne (réservée aux administrations d'État)
    textTheme: GoogleFonts.interTextTheme(),

    scaffoldBackgroundColor: fondDsfr,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: titreDsfr,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: titreDsfr,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: bordureDsfr, width: 1),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bleuRepublique,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: bordureDsfr,
      thickness: 1,
      space: 0,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: fondDsfr,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.inter(fontSize: 12),
      ),
    ),

    useMaterial3: true,
  );
}
