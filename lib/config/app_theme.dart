import 'package:flutter/material.dart';

// Thème global de l'app SOS Canicule
// Inspiré du DSFR (Design System de l'État français)
// Centralisé ici pour garder main.dart propre
// → si une couleur change, on ne modifie qu'un seul endroit
class AppTheme {

  // -------------------------
  // COULEURS DSFR
  // -------------------------
  static const Color bleuRepublique  = Color(0xFF000091); // primaire
  static const Color vertDsfr        = Color(0xFF18753C); // niveau VERT
  static const Color orangeDsfr      = Color(0xFFB34000); // niveau ORANGE
  static const Color rougeDsfr       = Color(0xFFCE0500); // niveau ROUGE
  static const Color fondDsfr        = Color(0xFFF5F5FE); // fond bleu-blanc
  static const Color bordureDsfr     = Color(0xFFDDDDDD); // bordures cartes
  static const Color bleuAction      = Color(0xFF0063CB); // bleu liens/actions
  static const Color bleuClairDsfr   = Color(0xFFE3E3FD); // indicateur nav bar
  static const Color bleuBadgeDsfr   = Color(0xFFEEEEFF); // fond badge type
  static const Color rougeTricolore  = Color(0xFFE1000F); // rouge drapeau français
  static const Color titreDsfr       = Color(0xFF1E1E1E); // couleur des titres
  static const Color griseTexteDsfr  = Color(0xFF666666); // texte secondaire

  // -------------------------
  // THÈME MATERIAL 3
  // -------------------------
  static ThemeData get theme => ThemeData(

    // Bleu République comme couleur principale
    colorScheme: ColorScheme.fromSeed(
      seedColor: bleuRepublique,
      primary:   bleuRepublique,
      secondary: vertDsfr,
      error:     rougeDsfr,
      surface:   fondDsfr,
    ),

    // Police Marianne = fonte officielle de la République française
    // Déclarée dans pubspec.yaml → assets/fonts/
    fontFamily: 'Marianne',

    // AppBar: fond blanc, texte bleu République, sans ombre (flat DSFR)
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: bleuRepublique,
      elevation: 0,
      centerTitle: false,
    ),

    // Cartes: coins 8px, bordure grise légère, sans ombre (flat DSFR)
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(
          color: bordureDsfr,
          width: 1,
        ),
      ),
    ),

    // Boutons principaux: bleu République, coins 4px (DSFR)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bleuRepublique,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    ),

    useMaterial3: true,
  );
}