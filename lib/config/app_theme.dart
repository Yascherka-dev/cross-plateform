import 'package:flutter/material.dart';

// Thème global de l'app SOS Canicule
// Palette réduite à l'essentiel: sobre, plat, lisible
// Inspiration: service-public.fr, app Météo France
class AppTheme {

  // -------------------------
  // PALETTE PRINCIPALE
  // 6 couleurs maximum dans toute l'app
  // -------------------------
  static const Color bleuRepublique = Color(0xFF000091); // primaire, liens, icônes actives
  static const Color fondDsfr       = Color(0xFFF5F5FE); // fond de page uniquement
  static const Color bordureDsfr    = Color(0xFFDDDDDD); // séparateurs et bordures
  static const Color titreDsfr      = Color(0xFF1E1E1E); // texte principal
  static const Color griseTexteDsfr = Color(0xFF666666); // texte secondaire

  // Couleurs de niveau de risque
  // Utilisées UNIQUEMENT sur la bannière principale (RiskBanner)
  static const Color vertDsfr   = Color(0xFF18753C); // niveau VERT
  static const Color orangeDsfr = Color(0xFFB34000); // niveau ORANGE
  static const Color rougeDsfr  = Color(0xFFCE0500); // niveau ROUGE

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

    // Police Marianne — fonte officielle de la République française
    fontFamily: 'Marianne',
    scaffoldBackgroundColor: fondDsfr,

    // AppBar: fond blanc, titre bleu République, sans ombre, sans centrage
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: bleuRepublique,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Marianne',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: bleuRepublique,
      ),
    ),

    // Cards: coins 4px, bordure grise fine, sans ombre — style plat DSFR
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: bordureDsfr, width: 1),
      ),
    ),

    // Boutons principaux: bleu République, coins 4px, sans ombre
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bleuRepublique,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // Séparateurs: gris clair, 1px, pas d'espacement supplémentaire
    dividerTheme: const DividerThemeData(
      color: bordureDsfr,
      thickness: 1,
      space: 0,
    ),

    // Navigation bar: fond blanc, indicateur très léger, sans ombre
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
