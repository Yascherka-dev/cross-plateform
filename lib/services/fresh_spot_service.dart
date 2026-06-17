import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fresh_spot.dart';
import '../config/app_config.dart';
import 'location_service.dart';
import 'package:flutter/foundation.dart';

// Résultat agrégé : spots disponibles + sources OpenData qui n'ont pas répondu
class FreshSpotResult {
  final List<FreshSpot> spots;
  final List<String> sourcesEnEchec; // ex: ["Fontaines"]
  FreshSpotResult({required this.spots, required this.sourcesEnEchec});
}

class FreshSpotService {
  final LocationService _locationService = LocationService();

  // Cache 1h — les données OpenData Paris changent rarement
  List<FreshSpot>? _cachedSpots;
  DateTime? _lastFetch;

  Future<FreshSpotResult> fetchAllFreshSpots({
    required double userLat,
    required double userLon,
  }) async {
    if (_cachedSpots != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < AppConfig.freshSpotCacheDuration) {
        // Cache alimenté uniquement quand tout a répondu → aucune source en échec
        return FreshSpotResult(
          spots: _addDistances(_cachedSpots!, userLat, userLon),
          sourcesEnEchec: const [],
        );
      }
    }

    final results = await Future.wait([
      _fetchEspacesVerts(),
      _fetchEquipements(),
      _fetchFontaines(),
    ]);

    final List<FreshSpot> allSpots = [
      ...results[0].$1,
      ...results[1].$1,
      ...results[2].$1,
    ];

    // Chaque _fetch renvoie (spots, succès) → on liste les sources KO
    final echecs = <String>[
      if (!results[0].$2) 'Espaces verts',
      if (!results[1].$2) 'Équipements',
      if (!results[2].$2) 'Fontaines',
    ];

    // On ne met en cache que les données complètes, pour qu'un "Réessayer"
    // relance vraiment les sources tombées au lieu de servir du partiel
    if (echecs.isEmpty) {
      _cachedSpots = allSpots;
      _lastFetch = DateTime.now();
    }

    return FreshSpotResult(
      spots: _addDistances(allSpots, userLat, userLon),
      sourcesEnEchec: echecs,
    );
  }

  Future<(List<FreshSpot>, bool)> _fetchEspacesVerts() async {
    try {
      final url = Uri.parse(
        '${AppConfig.espacesVertsFraisDataset}'
        '?limit=${AppConfig.openDataLimit}'
        '&select=identifiant,nom,type,categorie,proportion_vegetation_haute,'
        'adresse,arrondissement,statut_ouverture,ouvert_24h,canicule_ouverture,'
        'ouverture_estivale_nocturne,geo_point_2d,'
        'horaires_lundi,horaires_mardi,horaires_mercredi,horaires_jeudi,'
        'horaires_vendredi,horaires_samedi,horaires_dimanche',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List records = json['results'] ?? [];
        return (records.map((r) => FreshSpot.fromJsonEspaceVert(r)).toList(), true);
      }
      return (<FreshSpot>[], false);
    } catch (e) {
      debugPrint('Erreur espaces verts: $e');
      return (<FreshSpot>[], false);
    }
  }

  Future<(List<FreshSpot>, bool)> _fetchEquipements() async {
    try {
      final url = Uri.parse(
        '${AppConfig.equipementsFraisDataset}'
        '?limit=${AppConfig.openDataLimit}'
        '&select=identifiant,nom,type,payant,adresse,arrondissement,statut_ouverture,geo_point_2d,'
        'horaires_lundi,horaires_mardi,horaires_mercredi,horaires_jeudi,'
        'horaires_vendredi,horaires_samedi,horaires_dimanche',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List records = json['results'] ?? [];
        return (records.map((r) => FreshSpot.fromJsonEquipement(r)).toList(), true);
      }
      return (<FreshSpot>[], false);
    } catch (e) {
      debugPrint('Erreur équipements: $e');
      return (<FreshSpot>[], false);
    }
  }

  Future<(List<FreshSpot>, bool)> _fetchFontaines() async {
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
        return (records.map((r) => FreshSpot.fromJsonFontaine(r)).toList(), true);
      }
      return (<FreshSpot>[], false);
    } catch (e) {
      debugPrint('Erreur fontaines: $e');
      return (<FreshSpot>[], false);
    }
  }

  List<FreshSpot> _addDistances(List<FreshSpot> spots, double userLat, double userLon) {
    final result = spots.map((spot) {
      final d = _locationService.distanceTo(
        userLat: userLat,
        userLon: userLon,
        spotLat: spot.latitude,
        spotLon: spot.longitude,
      );
      return spot.copyWithDistance(d);
    }).toList();
    result.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    return result;
  }

  List<FreshSpot> filterByType(List<FreshSpot> spots, FreshSpotType? type) {
    if (type == null) return spots;
    return spots.where((s) => s.type == type).toList();
  }
}
