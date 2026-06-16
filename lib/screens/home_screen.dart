import 'package:flutter/material.dart';
import '../config/app_theme.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final WeatherService   _weatherService   = WeatherService();
  final LocationService  _locationService  = LocationService();
  final FreshSpotService _freshSpotService = FreshSpotService();
  final SupabaseService  _supabaseService  = SupabaseService();

  int _currentIndex = 0;

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

    final freshSpots = parallelResults[0] as List<FreshSpot>;
    final thresholds = parallelResults[1] as Map<String, Map<String, dynamic>>;

    final orange = thresholds['orange'];
    final rouge  = thresholds['rouge'];

    final riskLevel = calculateHeatRisk(
      temp:      weather.temperature,
      feelsLike: weather.feelsLike,
      humidity:  weather.humidity,
      uvNow:     weather.uvNow,
      peakTemp:  weather.peakTemp,
      peakUv:    weather.peakUv,
      seuilTempOrange: (orange!['seuil_temp']       as num).toDouble(),
      seuilTempRouge:  (rouge!['seuil_temp']        as num).toDouble(),
      seuilUvOrange:   (orange['seuil_uv']          as num).toDouble(),
      seuilUvRouge:    (rouge['seuil_uv']           as num).toDouble(),
      humiditeBoost1:  (orange['humidite_boost_1']  as num).toInt(),
      humiditeBoost2:  (orange['humidite_boost_2']  as num).toInt(),
    );

    return {
      'weather':    weather,
      'riskLevel':  riskLevel,
      'freshSpots': freshSpots,
    };
  }

  Future<void> _refresh() async {
    _dataFuture = _fetchAllData();
    setState(() => _refreshKey++);
    await _dataFuture;
  }

  Widget _buildScreen(
    WeatherData weather,
    HeatRiskLevel riskLevel,
    List<FreshSpot> freshSpots,
  ) {
    switch (_currentIndex) {
      case 1:
        return MapScreen(freshSpots: freshSpots);
      case 2:
        return AdviceScreen(riskLevel: riskLevel);
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
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Bannière niveau de risque
            RiskBanner(riskLevel: riskLevel, weather: weather),

            const SizedBox(height: 24),

            // Section "Que faire ?"
            const Text(
              'Que faire ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.titreDsfr,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.location_on_outlined, color: AppTheme.bleuRepublique),
                    title: const Text(
                      'Points de fraîcheur',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      '${freshSpots.length} lieux autour de vous',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.griseTexteDsfr,
                    ),
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.health_and_safety_outlined, color: AppTheme.bleuRepublique),
                    title: const Text(
                      'Conseils et premiers secours',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: const Text(
                      "Signes, gestes et numéros d'urgence",
                      style: TextStyle(fontSize: 13),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.griseTexteDsfr,
                    ),
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section "Les plus proches de vous"
            const Text(
              'Les plus proches de vous',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.titreDsfr,
              ),
            ),

            const SizedBox(height: 12),

            if (spots.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    for (int i = 0; i < spots.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      FreshSpotTile(spot: spots[i]),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondDsfr,

      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo48.png', height: 32),
            const SizedBox(width: 10),
            const Text('SOS Canicule'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
            tooltip: 'Actualiser',
          ),
        ],
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshKey),
        future: _dataFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.bleuRepublique),
                  SizedBox(height: 16),
                  Text('Récupération de votre position...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 64,
                      color: AppTheme.rougeDsfr,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _refresh(),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data       = snapshot.data!;
          final weather    = data['weather']    as WeatherData;
          final riskLevel  = data['riskLevel']  as HeatRiskLevel;
          final freshSpots = data['freshSpots'] as List<FreshSpot>;
          return _buildScreen(weather, riskLevel, freshSpots);
        },
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'Conseils',
          ),
        ],
      ),
    );
  }
}
