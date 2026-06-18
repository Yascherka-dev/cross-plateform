import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../logic/heat_risk_level.dart';
import '../models/weather_data.dart';
import '../models/fresh_spot.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/fresh_spot_service.dart';
import '../services/supabase_service.dart';
import '../widgets/risk_banner.dart';
import '../widgets/fresh_spot_tile.dart';
import 'map_screen.dart';
import 'advice_screen.dart';
import 'emergency_screen.dart';
import 'favoris_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final FreshSpotService _freshSpotService = FreshSpotService();
  final SupabaseService _supabaseService = SupabaseService();

  int _currentIndex = 0;
  FreshSpot? _spotInitial; // spot à ouvrir directement sur la carte

  late Future<Map<String, dynamic>> _dataFuture;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchAllData();
  }

  Future<Map<String, dynamic>> _fetchAllData() async {
    final position = await _locationService.getCurrentPosition();

    final weather = await _weatherService.fetchWeather(
      position.latitude,
      position.longitude,
    );

    final parallelResults = await Future.wait([
      _freshSpotService.fetchAllFreshSpots(
        userLat: position.latitude,
        userLon: position.longitude,
      ),
      _supabaseService.fetchHeatThresholds(),
    ]);

    final spotsResult = parallelResults[0] as FreshSpotResult;
    final thresholds = parallelResults[1] as Map<String, Map<String, dynamic>>;

    final orange = thresholds['orange'];
    final rouge = thresholds['rouge'];

    final riskLevel = calculateHeatRisk(
      temp: weather.temperature,
      feelsLike: weather.feelsLike,
      humidity: weather.humidity,
      uvNow: weather.uvNow,
      peakTemp: weather.peakTemp,
      peakUv: weather.peakUv,
      seuilTempOrange: (orange!['seuil_temp'] as num).toDouble(),
      seuilTempRouge: (rouge!['seuil_temp'] as num).toDouble(),
      seuilUvOrange: (orange['seuil_uv'] as num).toDouble(),
      seuilUvRouge: (rouge['seuil_uv'] as num).toDouble(),
      humiditeBoost1: (orange['humidite_boost_1'] as num).toInt(),
      humiditeBoost2: (orange['humidite_boost_2'] as num).toInt(),
    );

    return {
      'weather': weather,
      'riskLevel': riskLevel,
      'freshSpots': spotsResult.spots,
      'sourcesEnEchec': spotsResult.sourcesEnEchec,
    };
  }

  Future<void> _refresh() async {
    _dataFuture = _fetchAllData();
    setState(() => _refreshKey++);
    await _dataFuture;
  }

  // Ouvre l'onglet Carte directement sur un spot précis.
  void _ouvrirSpotSurCarte(FreshSpot spot) {
    setState(() {
      _spotInitial = spot;
      _currentIndex = 1;
    });
  }

  // Changement d'onglet manuel : pas d'ouverture automatique de spot.
  void _changerOnglet(int index) {
    setState(() {
      _spotInitial = null;
      _currentIndex = index;
    });
  }

  Widget _buildScreen(
    WeatherData weather,
    HeatRiskLevel riskLevel,
    List<FreshSpot> freshSpots,
    List<String> sourcesEnEchec,
  ) {
    switch (_currentIndex) {
      case 1:
        return MapScreen(
          freshSpots: freshSpots,
          sourcesEnEchec: sourcesEnEchec,
          onRetry: _refresh,
          spotInitial: _spotInitial,
        );
      case 2:
        return AdviceScreen(riskLevel: riskLevel);
      case 3:
        return const EmergencyScreen();
      default:
        return _buildHomeContent(weather, riskLevel, freshSpots);
    }
  }

  Widget _buildHomeContent(
    WeatherData weather,
    HeatRiskLevel riskLevel,
    List<FreshSpot> freshSpots,
  ) {
    final spots = freshSpots.take(3).toList();

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.surface,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingSm,
          AppTheme.spacingLg,
          AppTheme.spacingXxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RiskBanner(
              riskLevel: riskLevel,
              weather: weather,
            ),
            const SizedBox(height: 14),
            const _HydrationReminder(),
            const SizedBox(height: 24),
            const _SectionTitle('Que faire ?'),
            const SizedBox(height: 10),
            _QuickActionsCard(
              freshSpotCount: freshSpots.length,
              onMapTap: () => _changerOnglet(1),
              onAdviceTap: () => _changerOnglet(2),
              onEmergencyTap: () => _changerOnglet(3),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Les plus proches'),
            const SizedBox(height: 10),
            if (spots.isNotEmpty)
              Column(
                children: [
                  for (final spot in spots) ...[
                    GestureDetector(
                      onTap: () => _ouvrirSpotSurCarte(spot),
                      child: FreshSpotTile(spot: spot),
                    ),
                    const SizedBox(height: 9),
                  ],
                ],
              )
            else
              const _EmptyFreshSpotsCard(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.fond,
        surfaceTintColor: Colors.transparent,
        titleSpacing: AppTheme.spacingLg,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(9),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/logo48.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) {
                  return const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.white,
                    size: 18,
                  );
                },
              ),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOS Canicule',
                  style: AppTheme.titre(16),
                ),
                Text(
                  'Paris · à l’instant',
                  style: AppTheme.label(
                    size: 10.5,
                    color: AppTheme.texteSecondaire,
                    weight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            color: AppTheme.texteSecondaire,
            tooltip: 'Mes favoris',
            onPressed: () async {
              // Le tap sur un favori renvoie le spot → ouverture sur la carte.
              final spot = await Navigator.push<FreshSpot?>(
                context,
                MaterialPageRoute(builder: (_) => const FavorisScreen()),
              );
              if (spot != null) _ouvrirSpotSurCarte(spot);
            },
          ),
          const _AccountAction(),
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              color: AppTheme.texteSecondaire,
              onPressed: _refresh,
              tooltip: 'Actualiser',
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshKey),
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          final weather = data['weather'] as WeatherData;
          final riskLevel = data['riskLevel'] as HeatRiskLevel;
          final freshSpots = data['freshSpots'] as List<FreshSpot>;
          final sourcesEnEchec = data['sourcesEnEchec'] as List<String>;

          return _buildScreen(
            weather,
            riskLevel,
            freshSpots,
            sourcesEnEchec,
          );
        },
      ),
      bottomNavigationBar: _WarmBottomNavigation(
        currentIndex: _currentIndex,
        onSelected: _changerOnglet,
      ),
    );
  }
}

// Point d'entrée connexion/inscription dans l'AppBar.
// Réagit en temps réel à l'état d'authentification.
class _AccountAction extends StatelessWidget {
  const _AccountAction();

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, _) {
        final user = authService.currentUser;

        // Déconnecté : icône neutre → écran de connexion
        if (user == null) {
          return IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            color: AppTheme.texteSecondaire,
            tooltip: 'Se connecter',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          );
        }

        // Connecté : icône accent + menu (pseudo/email, déconnexion)
        final pseudo = (user.userMetadata?['pseudo'] as String?)?.trim();
        final label = (pseudo != null && pseudo.isNotEmpty)
            ? pseudo
            : (user.email ?? 'Mon compte');

        return PopupMenuButton<String>(
          icon: const Icon(
            Icons.account_circle_rounded,
            color: AppTheme.accent,
          ),
          tooltip: 'Mon compte',
          color: AppTheme.surface,
          onSelected: (value) {
            if (value == 'logout') authService.signOut();
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                label,
                style: AppTheme.body(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppTheme.textePrincipal,
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Text(
                'Se déconnecter',
                style: AppTheme.body(size: 13, color: AppTheme.rougeTexte),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HydrationReminder extends StatelessWidget {
  const _HydrationReminder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCarte),
        border: Border.all(color: AppTheme.bordure),
        boxShadow: AppTheme.ombreBase,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.fontaineFond,
              borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: AppTheme.fontaineTexte,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pensez à vous hydrater',
                  style: AppTheme.body(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: AppTheme.textePrincipal,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  "Un verre d'eau toutes les heures",
                  style: AppTheme.body(
                    size: 11.5,
                    color: AppTheme.texteSecondaire,
                  ),
                ),
              ],
            ),
          ),
          const _HydrationDots(),
        ],
      ),
    );
  }
}

class _HydrationDots extends StatelessWidget {
  const _HydrationDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final active = index < 3;

        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: active ? AppTheme.fontaineTexte : AppTheme.fontaineFond,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.sectionLabel(),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final int freshSpotCount;
  final VoidCallback onMapTap;
  final VoidCallback onAdviceTap;
  final VoidCallback onEmergencyTap;

  const _QuickActionsCard({
    required this.freshSpotCount,
    required this.onMapTap,
    required this.onAdviceTap,
    required this.onEmergencyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCarte),
        border: Border.all(color: AppTheme.bordure),
        boxShadow: AppTheme.ombreBase,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _QuickActionTile(
            icon: Icons.pin_drop_rounded,
            iconColor: AppTheme.fontaineTexte,
            iconBackground: AppTheme.fontaineFond,
            title: 'Points de fraîcheur',
            subtitle: '$freshSpotCount lieux autour de vous',
            onTap: onMapTap,
          ),
          const Divider(),
          _QuickActionTile(
            icon: Icons.health_and_safety_rounded,
            iconColor: AppTheme.parcTexte,
            iconBackground: AppTheme.parcFond,
            title: 'Conseils',
            subtitle: 'Signes & gestes de prévention',
            onTap: onAdviceTap,
          ),
          const Divider(),
          _QuickActionTile(
            icon: Icons.emergency_rounded,
            iconColor: AppTheme.rougeTexte,
            iconBackground: AppTheme.rougeFond,
            title: 'Urgence immédiate',
            subtitle: "Numéros d'urgence",
            onTap: onEmergencyTap,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: AppTheme.fond,
      splashColor: AppTheme.fond,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppTheme.textePrincipal,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTheme.body(
                      size: 12,
                      color: AppTheme.texteSecondaire,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.iconeDiscrete,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFreshSpotsCard extends StatelessWidget {
  const _EmptyFreshSpotsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCarte),
        border: Border.all(color: AppTheme.bordure),
        boxShadow: AppTheme.ombreBase,
      ),
      child: Text(
        'Aucun point de fraîcheur trouvé autour de vous pour le moment.',
        style: AppTheme.body(
          size: 13,
          color: AppTheme.texteSecondaire,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCarte),
          border: Border.all(color: AppTheme.bordure),
          boxShadow: AppTheme.ombreBase,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppTheme.accent,
            ),
            const SizedBox(height: 16),
            Text(
              'Récupération de votre position...',
              style: AppTheme.body(
                size: 13,
                color: AppTheme.texteSecondaire,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXxl),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusHero),
            border: Border.all(color: AppTheme.bordure),
            boxShadow: AppTheme.ombreBase,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_rounded,
                size: 56,
                color: AppTheme.rougeTexte,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  size: 14,
                  color: AppTheme.texteSurface,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarmBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _WarmBottomNavigation({
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const _WarmNavItem(
        label: 'Accueil',
        icon: Icons.home_rounded,
      ),
      const _WarmNavItem(
        label: 'Carte',
        icon: Icons.map_rounded,
      ),
      const _WarmNavItem(
        label: 'Conseils',
        icon: Icons.health_and_safety_rounded,
      ),
      const _WarmNavItem(
        label: 'Urgences',
        icon: Icons.emergency_rounded,
      ),
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppTheme.fond,
        border: Border(
          top: BorderSide(color: AppTheme.separateur),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _WarmNavButton(
                item: items[i],
                active: i == currentIndex,
                onTap: () => onSelected(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _WarmNavItem {
  final String label;
  final IconData icon;

  const _WarmNavItem({
    required this.label,
    required this.icon,
  });
}

class _WarmNavButton extends StatelessWidget {
  final _WarmNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _WarmNavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.accent : AppTheme.texteTertiaire;

    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: active ? 20 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(3),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    color: color,
                    size: 23,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.label,
                    style: AppTheme.label(
                      size: 10,
                      color: color,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}