import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/weather_data.dart';
import '../models/fresh_spot.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/fresh_spot_service.dart';
import '../services/supabase_service.dart';
import 'map_screen.dart';
import 'advice_screen.dart';

// Écran principal de l'app
// Gère: géoloc → météo → calcul du niveau → affichage de l'alerte
// StatefulWidget car l'état change (index de navigation + clé de refresh)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // Services injectés dans l'écran
  final WeatherService   _weatherService   = WeatherService();
  final LocationService  _locationService  = LocationService();
  final FreshSpotService _freshSpotService = FreshSpotService();
  final SupabaseService  _supabaseService  = SupabaseService();

  // Index de l'onglet actif dans la bottom nav bar
  // 0 = Accueil / 1 = Carte / 2 = Conseils
  int _currentIndex = 0;

  // Future stocké pour que _refresh() puisse l'attendre
  // sans relancer un deuxième appel API en parallèle
  late Future<Map<String, dynamic>> _dataFuture;

  // Clé incrémentée à chaque refresh: changer la ValueKey du FutureBuilder
  // force Flutter à recréer le widget et relancer le Future
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    // Lancement du chargement initial dès la création de l'écran
    _dataFuture = _fetchAllData();
  }

  // Méthode principale de chargement: géoloc → météo → calcul → spots
  // Retourne toutes les données dans une Map pour le FutureBuilder
  Future<Map<String, dynamic>> _fetchAllData() async {
    // ÉTAPE 1: Récupération de la position GPS
    // Lance la demande de permission si nécessaire
    final position = await _locationService.getCurrentPosition();

    // ÉTAPE 2: Appel Open-Meteo avec les coordonnées GPS réelles
    final weather = await _weatherService.fetchWeather(
      position.latitude,
      position.longitude,
    );

    // ÉTAPE 3: Fresh spots + seuils Supabase en PARALLÈLE
    // Les deux sont indépendants l'un de l'autre → on gagne du temps
    final parallelResults = await Future.wait([
      _freshSpotService.fetchAllFreshSpots(
        userLat: position.latitude,
        userLon: position.longitude,
      ),
      _supabaseService.fetchHeatThresholds(),
    ]);

    final freshSpots = parallelResults[0] as List<FreshSpot>;
    final thresholds = parallelResults[1] as Map<String, Map<String, dynamic>>;

    // ÉTAPE 4: Calcul du niveau de risque avec les seuils Supabase
    // Si Supabase est inaccessible, fetchHeatThresholds() retourne le fallback local
    // → les valeurs par défaut de calculateHeatRisk s'appliquent de toute façon
    final orange = thresholds['orange'];
    final rouge  = thresholds['rouge'];

    final riskLevel = calculateHeatRisk(
      temp:      weather.temperature,
      feelsLike: weather.feelsLike,
      humidity:  weather.humidity,
      uvNow:     weather.uvNow,
      peakTemp:  weather.peakTemp,
      peakUv:    weather.peakUv,
      seuilTempOrange: (orange?['seuil_temp']       as num?)?.toDouble() ?? 30.0,
      seuilTempRouge:  (rouge?['seuil_temp']        as num?)?.toDouble() ?? 35.0,
      seuilUvOrange:   (orange?['seuil_uv']         as num?)?.toDouble() ?? 6.0,
      seuilUvRouge:    (rouge?['seuil_uv']          as num?)?.toDouble() ?? 8.0,
      humiditeBoost1:  (orange?['humidite_boost_1'] as num?)?.toInt()    ?? 60,
      humiditeBoost2:  (orange?['humidite_boost_2'] as num?)?.toInt()    ?? 70,
    );

    // Toutes les données regroupées dans une Map typée
    return {
      'weather':    weather,
      'riskLevel':  riskLevel,
      'freshSpots': freshSpots,
    };
  }

  // Relance le chargement complet:
  // 1. Crée un seul nouveau Future (pas de double appel API)
  // 2. Incrémente la clé → FutureBuilder recrée son widget et utilise le nouveau Future
  // 3. Await permet au RefreshIndicator de fermer son spinner quand c'est fini
  Future<void> _refresh() async {
    _dataFuture = _fetchAllData();
    setState(() => _refreshKey++);
    await _dataFuture;
  }

  // Retourne la couleur de fond de la bannière selon le niveau de risque
  // Couleurs du DSFR (Design System de l'État français)
  Color _getRiskColor(HeatRiskLevel riskLevel) {
    switch (riskLevel) {
      case HeatRiskLevel.vert:   return AppTheme.vertDsfr;
      case HeatRiskLevel.orange: return AppTheme.orangeDsfr;
      case HeatRiskLevel.rouge:  return AppTheme.rougeDsfr;
    }
  }

  // Retourne le label texte du niveau de risque affiché dans la bannière
  String _getRiskLabel(HeatRiskLevel riskLevel) {
    switch (riskLevel) {
      case HeatRiskLevel.vert:   return 'Risque faible';
      case HeatRiskLevel.orange: return 'Vigilance orange';
      case HeatRiskLevel.rouge:  return 'Alerte rouge canicule';
    }
  }

  // Retourne le bon écran selon l'onglet sélectionné
  // Appelé depuis le FutureBuilder une fois les données disponibles
  Widget _buildScreen(
    WeatherData weather,
    HeatRiskLevel riskLevel,
    List<FreshSpot> freshSpots,
  ) {
    switch (_currentIndex) {
      case 1:
        // Écran carte — reçoit les fresh spots déjà chargés
        // pour ne pas refaire un appel API inutile
        return MapScreen(freshSpots: freshSpots);
      case 2:
        // Écran conseils — reçoit le niveau de risque actuel
        // pour filtrer les fiches selon la dangerosité
        return AdviceScreen(riskLevel: riskLevel);
      default:
        // Écran accueil — contenu principal
        return _buildHomeContent(weather, riskLevel, freshSpots);
    }
  }

  // Contenu principal de l'écran accueil
  // Extrait dans une méthode pour garder build() lisible
  Widget _buildHomeContent(
    WeatherData weather,
    HeatRiskLevel riskLevel,
    List<FreshSpot> freshSpots,
  ) {
    return RefreshIndicator(
      // Pull-to-refresh: _refresh() relance le chargement complet
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // -----------------------------------------------
            // BANNIÈRE ALERTE PRINCIPALE
            // Couleur et label adaptés au niveau de risque
            // -----------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getRiskColor(riskLevel),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label du niveau (Risque faible / Vigilance orange / Alerte rouge)
                  Text(
                    _getRiskLabel(riskLevel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Température actuelle affichée en très grand
                  Text(
                    '${weather.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Ligne 1: ressenti + UV actuel + humidité
                  Text(
                    'Ressenti ${weather.feelsLike.toStringAsFixed(1)}°C '
                    '• UV ${weather.uvNow.toStringAsFixed(1)} '
                    '• Humidité ${weather.humidity}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Ligne 2: pic de température et UV max de la journée
                  Text(
                    "Pic aujourd'hui: ${weather.peakTemp.toStringAsFixed(1)}°C "
                    '• UV max ${weather.peakUv.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------
            // SECTION "QUE FAIRE ?"
            // Deux cartes d'action cliquables
            // -----------------------------------------------
            const Text(
              'Que faire ?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.titreDsfr,
              ),
            ),

            const SizedBox(height: 12),

            // Carte action 1: Points de fraîcheur → écran Carte
            _ActionCard(
              icon: Icons.location_on,
              iconColor: AppTheme.bleuAction,
              title: 'Points de fraîcheur',
              subtitle: '${freshSpots.length} lieux trouvés autour de vous',
              onTap: () => setState(() => _currentIndex = 1),
            ),

            const SizedBox(height: 12),

            // Carte action 2: Conseils → écran Conseils
            _ActionCard(
              icon: Icons.health_and_safety,
              iconColor: AppTheme.rougeDsfr,
              title: 'Conseils et premiers secours',
              subtitle: "Signes, gestes et numéros d'urgence",
              onTap: () => setState(() => _currentIndex = 2),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------
            // SECTION "LES PLUS PROCHES DE VOUS"
            // Les 3 fresh spots les plus proches triés par distance
            // -----------------------------------------------
            const Text(
              'Les plus proches de vous',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.titreDsfr,
              ),
            ),

            const SizedBox(height: 12),

            // take(3) = on n'affiche que les 3 premiers
            // Le tri par distance est fait dans FreshSpotService
            ...freshSpots.take(3).map((spot) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FreshSpotCard(spot: spot),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fondDsfr,

      // APPBAR avec logo de l'app et nom
      appBar: AppBar(
        title: Row(
          children: [
            // Logo de l'app à taille AppBar (32px de hauteur)
            Image.asset(
              'assets/images/logo48.png',
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'SOS Canicule',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.bleuRepublique,
              ),
            ),
          ],
        ),
        // Bouton refresh manuel en haut à droite
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
            tooltip: 'Actualiser',
          ),
        ],
      ),

      // BODY: FutureBuilder gère les 3 états (chargement / erreur / données)
      // ValueKey(_refreshKey): incrémenter la clé recrée le widget
      // et relance le Future → effet refresh propre sans setState sur les données
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_refreshKey),
        future: _dataFuture,
        builder: (context, snapshot) {

          // État 1: chargement en cours
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

          // État 2: erreur (GPS désactivé, pas de réseau...)
          // On affiche un message explicite avec bouton "réessayer"
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

          // État 3: données disponibles → on affiche le bon écran
          final data       = snapshot.data!;
          final weather    = data['weather']    as WeatherData;
          final riskLevel  = data['riskLevel']  as HeatRiskLevel;
          final freshSpots = data['freshSpots'] as List<FreshSpot>;
          return _buildScreen(weather, riskLevel, freshSpots);
        },
      ),

      // BOTTOM NAVIGATION BAR
      // Permet de naviguer entre les 3 écrans principaux
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          // setState() déclenche un rebuild qui appelle _buildScreen()
          // avec le nouvel index → l'écran change
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.bleuClairDsfr,
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

// -----------------------------------------------
// WIDGET: _ActionCard
// Carte d'action cliquable avec icône, titre et sous-titre
// Réutilisable pour "Points de fraîcheur" et "Conseils"
// -----------------------------------------------
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        // Icône dans un container coloré arrondi
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            // withValues() = version non-deprecated de withOpacity()
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.griseTexteDsfr,
        ),
        onTap: onTap,
      ),
    );
  }
}

// -----------------------------------------------
// WIDGET: _FreshSpotCard
// Carte d'un point de fraîcheur dans la liste "les plus proches"
// Affiche: icône colorée, nom, type, statut ouvert/fermé, distance
// -----------------------------------------------
class _FreshSpotCard extends StatelessWidget {
  final FreshSpot spot;

  const _FreshSpotCard({required this.spot});

  @override
  Widget build(BuildContext context) {
    // Conversion du colorHex (#0063CB) en Color Flutter (0xFF0063CB)
    final Color spotColor = Color(
      int.parse(spot.type.colorHex.replaceFirst('#', '0xFF')),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [

            // Icône colorée selon le type de spot
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: spotColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                // Icône différente selon le type
                spot.type == FreshSpotType.fontaine
                    ? Icons.water_drop
                    : spot.type == FreshSpotType.parc
                        ? Icons.park
                        : Icons.ac_unit, // snowflake pour équipement frais
                color: spotColor,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            // Colonne: nom + badges (type + statut)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du lieu (tronqué si trop long)
                  Text(
                    spot.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Ligne de badges
                  Row(
                    children: [
                      // Badge type (Fontaine / Espace vert / Équipement frais)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bleuBadgeDsfr,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          spot.type.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.bleuRepublique,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Statut ouvert/fermé avec couleur DSFR
                      Text(
                        spot.estOuvert ? '✓ Ouvert' : '✗ Fermé',
                        style: TextStyle(
                          fontSize: 11,
                          color: spot.estOuvert
                              ? AppTheme.vertDsfr
                              : AppTheme.rougeDsfr,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Distance depuis l'utilisateur (ex: "202 m" ou "1.5 km")
            Text(
              spot.distanceLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.griseTexteDsfr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
