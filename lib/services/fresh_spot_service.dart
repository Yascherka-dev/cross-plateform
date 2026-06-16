import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fresh_spot.dart';
import '../config/app_config.dart';
import 'location_service.dart';
import 'package:flutter/foundation.dart'; // nécessaire pour debugPrint

// Service responsable de la récupération des points de fraîcheur
// depuis les 3 datasets OpenData Paris
// Les 3 appels sont lancés EN PARALLÈLE pour gagner du temps
class FreshSpotService {
  // Instance du service de géolocalisation
  // utilisée pour calculer les distances
  final LocationService _locationService = LocationService();

  // Cache local pour éviter de rappeler l'API trop souvent
  // Les données OpenData Paris ne changent pas souvent → 1h de cache
  List<FreshSpot>? _cachedSpots;
  DateTime? _lastFetch;

  // Méthode principale: récupère tous les points de fraîcheur
  // autour de la position GPS de l'utilisateur
  // lat et lon viennent du LocationService
  Future<List<FreshSpot>> fetchAllFreshSpots({
    required double userLat,
    required double userLon,
  }) async {
    // Vérification du cache: données valides moins d'1h → on les retourne
    if (_cachedSpots != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < AppConfig.freshSpotCacheDuration) {
        // On recalcule quand même les distances car l'utilisateur
        // a pu se déplacer depuis le dernier appel
        return _addDistances(_cachedSpots!, userLat, userLon);
      }
    }

    // On lance les 3 appels API EN PARALLÈLE avec Future.wait()
    // Sans ça on attendrait: appel1 + appel2 + appel3 (séquentiel)
    // Avec Future.wait() on attend: max(appel1, appel2, appel3) (parallèle)
    final results = await Future.wait([
      _fetchEspacesVerts(),
      _fetchEquipements(),
      _fetchFontaines(),
    ]);

    // On fusionne les 3 listes en une seule
    final List<FreshSpot> allSpots = [
      ...results[0], // espaces verts frais
      ...results[1], // équipements frais
      ...results[2], // fontaines
    ];

    // Mise en cache de la liste complète
    _cachedSpots = allSpots;
    _lastFetch = DateTime.now();

    // On calcule et ajoute la distance pour chaque point
    return _addDistances(allSpots, userLat, userLon);
  }

  // Méthode privée: appelle le dataset espaces verts frais
  // Parcs et jardins classés par % d'ombrage (végétation haute)
  // Dans _fetchEspacesVerts() — remplace le select

  Future<List<FreshSpot>> _fetchEspacesVerts() async {
    try {
      final url = Uri.parse(
        '${AppConfig.espacesVertsFraisDataset}'
        '?limit=${AppConfig.openDataLimit}'
        '&select=identifiant,nom,type,categorie,proportion_vegetation_haute,'
        'adresse,statut_ouverture,ouvert_24h,canicule_ouverture,geo_point_2d',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List records = json['results'] ?? [];
        // On convertit chaque enregistrement JSON en objet FreshSpot
        return records
            .map((record) => FreshSpot.fromJsonEspaceVert(record))
            .toList();
      }
      // Si l'API échoue on retourne une liste vide
      // pour ne pas bloquer les autres datasets
      return [];
    } catch (e) {
      // On log l'erreur mais on ne plante pas l'app
      debugPrint('Erreur espaces verts: $e');
      return [];
    }
  }

  // Méthode privée: appelle le dataset équipements frais
  // Piscines, bibliothèques, musées, salles canicule...
  Future<List<FreshSpot>> _fetchEquipements() async {
    try {
      final url = Uri.parse(
        '${AppConfig.equipementsFraisDataset}'
        '?limit=${AppConfig.openDataLimit}'
        // champs confirmés par l'API réelle — "horaires" n'existe pas dans ce dataset
        '&select=identifiant,nom,type,payant,adresse,statut_ouverture,geo_point_2d',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List records = json['results'] ?? [];

        return records
            .map((record) => FreshSpot.fromJsonEquipement(record))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur équipements: $e');
      return [];
    }
  }
  

  // Méthode privée: appelle le dataset fontaines à boire
  // Fontaines Wallace, bornes, brumisateurs...
  Future<List<FreshSpot>> _fetchFontaines() async {
    try {
      final url = Uri.parse(
        '${AppConfig.fontainesDataset}'
        '?limit=${AppConfig.openDataLimit}'
        '&select=gid,type_objet,modele,voie,commune,dispo,motif_ind,geo_point_2d',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List records = json['results'] ?? [];

        return records
            .map((record) => FreshSpot.fromJsonFontaine(record))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur fontaines: $e');
      return [];
    }
  }

  // Méthode utilitaire: ajoute la distance calculée à chaque FreshSpot
  // et trie la liste du plus proche au plus loin
  List<FreshSpot> _addDistances(
    List<FreshSpot> spots,
    double userLat,
    double userLon,
  ) {
    // Pour chaque spot on calcule la distance depuis la position utilisateur
    final spotsWithDistance = spots.map((spot) {
      final distanceMetres = _locationService.distanceTo(
        userLat: userLat,
        userLon: userLon,
        spotLat: spot.latitude,
        spotLon: spot.longitude,
      );
      // copyWithDistance() crée une copie du spot avec la distance ajoutée
      return spot.copyWithDistance(distanceMetres);
    }).toList();

    // On trie du plus proche au plus loin
    // L'utilisateur voit en premier les points les plus accessibles
    spotsWithDistance.sort(
      (a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0),
    );

    return spotsWithDistance;
  }

  // Filtre les spots par type (utilisé par les chips sur la carte)
  // Si type est null → on retourne tous les spots
  List<FreshSpot> filterByType(List<FreshSpot> spots, FreshSpotType? type) {
    if (type == null) return spots;
    return spots.where((spot) => spot.type == type).toList();
  }
}
