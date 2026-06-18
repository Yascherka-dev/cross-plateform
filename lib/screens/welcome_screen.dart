import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

// Écran d'accueil affiché au lancement pour les visiteurs non connectés.
// Met en avant les avantages d'un compte sans rendre la connexion obligatoire.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Va vers l'écran de connexion ; si l'utilisateur s'authentifie,
  // on remplace Welcome par HomeScreen au retour.
  Future<void> _ouvrirConnexion(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!context.mounted) return;
    if (AuthService().currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  // Accès à l'app sans compte : app pleinement fonctionnelle.
  void _continuerSansCompte(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            children: [
              const Spacer(),

              // Logo
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusHero),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo128.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              Text(
                'SOS Canicule',
                style: AppTheme.titre(30),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              Text(
                'Créez un compte pour enregistrer vos lieux de fraîcheur '
                'favoris et les partager avec vos proches pendant les '
                'épisodes de canicule.',
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 14, color: AppTheme.texteSecondaire),
              ),

              const SizedBox(height: AppTheme.spacingXxl),

              // Avantages
              const _Avantage(
                icon: Icons.bookmark_added_rounded,
                texte: 'Enregistrez vos points de fraîcheur favoris',
              ),
              const SizedBox(height: AppTheme.spacingMd),
              const _Avantage(
                icon: Icons.ios_share_rounded,
                texte: 'Partagez-les avec vos proches',
              ),

              const Spacer(),

              // Bouton principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _ouvrirConnexion(context),
                  child: const Text('Se connecter / Créer un compte'),
                ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Bouton secondaire
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _continuerSansCompte(context),
                  child: const Text('Continuer sans compte'),
                ),
              ),

              const SizedBox(height: AppTheme.spacingSm),
            ],
          ),
        ),
      ),
    );
  }
}

// Ligne d'avantage : icône dans une pastille + texte.
class _Avantage extends StatelessWidget {
  final IconData icon;
  final String texte;

  const _Avantage({required this.icon, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.parcFond,
            borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
          ),
          child: Icon(icon, color: AppTheme.parcTexte, size: 20),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Text(
            texte,
            style: AppTheme.body(
              size: 13.5,
              weight: FontWeight.w600,
              color: AppTheme.texteSurface,
            ),
          ),
        ),
      ],
    );
  }
}
