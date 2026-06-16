import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/secrets.dart';
import 'screens/home_screen.dart';

// Point d'entrée de l'application Flutter
// C'est la première fonction appelée au lancement de l'app
Future<void> main() async {
  // Garantit que Flutter est initialisé avant tout appel natif
  // (géolocalisation, permissions, Supabase...) — obligatoire avant runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Supabase — doit être appelée avant runApp()
  // Les credentials sont dans lib/config/secrets.dart (gitignorée)
  await Supabase.initialize(
    url:            supabaseUrl,
    publishableKey: supabaseAnonKey,
  );

  // Lance l'application en passant le widget racine
  runApp(const SosCaniculeApp());
}

// Widget racine de l'application
// StatelessWidget car la config de l'app ne change jamais
class SosCaniculeApp extends StatelessWidget {
  const SosCaniculeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Nom affiché dans le gestionnaire de tâches du téléphone
      title: 'SOS Canicule',

      // Cache le bandeau rouge "DEBUG" en haut à droite
      debugShowCheckedModeBanner: false,

      // Thème global inspiré du DSFR (Design System de l'État français)
      theme: ThemeData(
        // Bleu République #000091 comme couleur primaire
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000091),
          primary: const Color(0xFF000091),   // bleu République
          secondary: const Color(0xFF18753C), // vert DSFR (niveau VERT)
          error: const Color(0xFFCE0500),     // rouge DSFR (niveau ROUGE)
          surface: const Color(0xFFF5F5FE), // fond bleu-blanc DSFR
        ),

        // Police Marianne = fonte officielle de la République française
        // Fallback sur sans-serif si non disponible
        fontFamily: 'Marianne',

        // Style des AppBar: fond blanc, texte bleu République
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF000091),
          elevation: 0, // pas d'ombre → flat design DSFR
          centerTitle: false,
        ),

        // Style global des cartes: coins arrondis 8px (DSFR)
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: Color(0xFFDDDDDD),
              width: 1,
            ),
          ),
          color: Colors.white,
        ),

        // Style des boutons principaux: bleu République
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000091),
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
      ),

      // Écran de démarrage = HomeScreen
      // C'est lui qui gère la géoloc et l'appel météo au lancement
      home: const HomeScreen(),
    );
  }
}