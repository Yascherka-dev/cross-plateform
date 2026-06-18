import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/weather_data.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/weather_service.dart';
import '../widgets/icon_pastille.dart';
import '../widgets/risk_banner.dart';
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

              const SizedBox(height: AppTheme.spacingLg),

              // Aperçu météo Paris (position fixe, pas de géoloc ici)
              const _ApercuMeteoParis(),

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

// Aperçu météo condensé basé sur Paris (coordonnées fixes), SANS géoloc.
// Discret et non bloquant : disparaît si l'appel réseau échoue.
class _ApercuMeteoParis extends StatefulWidget {
  const _ApercuMeteoParis();

  @override
  State<_ApercuMeteoParis> createState() => _ApercuMeteoParisState();
}

class _ApercuMeteoParisState extends State<_ApercuMeteoParis> {
  // Coordonnées fixes de Paris (pas la position de l'utilisateur).
  static const double _parisLat = 48.8566;
  static const double _parisLon = 2.3522;

  // Instances locales : le cache météo reste isolé de celui de HomeScreen.
  final _weatherService = WeatherService();
  final _supabaseService = SupabaseService();

  late final Future<({WeatherData weather, HeatRiskLevel risk})?> _future;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<({WeatherData weather, HeatRiskLevel risk})?> _charger() async {
    try {
      final weather = await _weatherService.fetchWeather(_parisLat, _parisLon);
      final seuils = await _supabaseService.fetchHeatThresholds();
      final orange = seuils['orange']!;
      final rouge = seuils['rouge']!;

      final risk = calculateHeatRisk(
        temp: weather.temperature,
        feelsLike: weather.feelsLike,
        humidity: weather.humidity,
        uvNow: weather.uvNow,
        peakTemp: weather.peakTemp,
        peakUv: weather.peakUv,
        seuilTempOrange: (orange['seuil_temp'] as num).toDouble(),
        seuilTempRouge: (rouge['seuil_temp'] as num).toDouble(),
        seuilUvOrange: (orange['seuil_uv'] as num).toDouble(),
        seuilUvRouge: (rouge['seuil_uv'] as num).toDouble(),
        humiditeBoost1: (orange['humidite_boost_1'] as num).toInt(),
        humiditeBoost2: (orange['humidite_boost_2'] as num).toInt(),
      );

      return (weather: weather, risk: risk);
    } catch (_) {
      // Pas de connexion / API indisponible : on n'affiche rien.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({WeatherData weather, HeatRiskLevel risk})?>(
      future: _future,
      builder: (context, snapshot) {
        // Chargement discret (pas de gros spinner qui domine l'écran).
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(
            'Météo à Paris…',
            style: AppTheme.label(size: 11, color: AppTheme.texteTertiaire),
          );
        }

        // Erreur ou pas de données : on n'affiche rien (Welcome normal).
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();

        // Réutilise RiskBanner en version compacte (source visuelle unique).
        return RiskBanner(
          weather: data.weather,
          riskLevel: data.risk,
          compact: true,
        );
      },
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
        IconPastille(
          icon: icon,
          color: AppTheme.parcTexte,
          background: AppTheme.parcFond,
          size: 40,
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
