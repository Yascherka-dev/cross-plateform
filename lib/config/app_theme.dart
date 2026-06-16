import 'package:flutter/material.dart';

class AppTheme {
  // Neutres
  static const Color fondDsfr       = Color(0xFFF0F4FF); // fond de page bleu pastel
  static const Color bordureDsfr    = Color(0xFFE5E7EB); // séparateurs et bordures
  static const Color titreDsfr      = Color(0xFF1A1A2E); // texte principal bleu nuit
  static const Color griseTexteDsfr = Color(0xFF6B7280); // texte secondaire (unique gris)
  static const Color bleuRepublique = Color(0xFF3B5BDB); // accent principal

  // Niveaux de risque — fond pastel + texte/bordure saturé
  static const Color vertFond   = Color(0xFFD3F9D8);
  static const Color vertDsfr   = Color(0xFF2F9E44); // texte et bordure vert
  static const Color orangeFond = Color(0xFFFFE8CC);
  static const Color orangeDsfr = Color(0xFFE67700); // texte et bordure orange
  static const Color rougeFond  = Color(0xFFFFE3E3);
  static const Color rougeDsfr  = Color(0xFFC92A2A); // texte et bordure rouge

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

    fontFamily: 'Marianne',
    scaffoldBackgroundColor: fondDsfr,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: titreDsfr,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Marianne',
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
        const TextStyle(fontFamily: 'Marianne', fontSize: 12),
      ),
    ),

    useMaterial3: true,
  );
}
