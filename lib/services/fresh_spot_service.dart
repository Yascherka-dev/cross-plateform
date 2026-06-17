import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fresh_spot.dart';
import '../config/app_config.dart';
import 'location_service.dart';
import 'package:flutter/foundation.dart';

class FreshSpotService {
  final LocationService _locationService = LocationService();

  // Cache 1h — les données OpenData Paris changent rarement
  List<FreshSpot>? _cachedSpots;
  DateTime? _lastFetch;

  Future<List<FreshSpot>> fetchAllFreshSpots({
    required double userLat,
    required double userLon,
  }) async {
    if (_cachedSpots != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < AppConfig.freshSpotCacheDuration) {
        // Distance recalculée même depuis le cache (position peut avoir changé)
        return _addDistances(_cachedSpots!, userLat, userLon);
      }
    }

    final results = await Future.wait([
      _fetchEspacesVerts(),
      _fetchEquipements(),
      _fetchFontaines(),
    ]);

    final List<FreshSpot> allSpots = [
      ...results[0],
      ...results[1],
      ...results[2],
    ];

    _cachedSpots = allSpots;
    _lastFetch = DateTime.now();

    return _addDistances(allSpots, userLat, userLon);
  }

  Future<List<FreshSpot>> _fetchEspacesVerts() async {
    try {
      final url = Uri.parse(
        '${AppConfig.espacesVertsFraisDataset}'
        '?limit=${AppConfig.openDataLimit}'
        '&select=identifiant,nom,type,categorie,proportion_vegetation_haute,'
        'adresse,arrondissement,statut_ouverture,ouvert_24h,canicule_ouverture,geo_point_2d,'
        'horaires_lundi,horaires_mardi,horaires_mercredi,horaires_jeudi,'
        'horaires_vendredi,horaires_samedi,horaires_dimanche',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List records = json['results'] ?? [];
        return records.map((r) => FreshSpot.fromJsonEspaceVert(r)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur espaces verts: $e');
      return [];
    }
  }

  Future<List<FreshSpot>> _fetchEquipements() async {
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
        return records.map((r) => FreshSpot.fromJsonEquipement(r)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur équipements: $e');
      return [];
    }
  }

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
        return records.map((r) => FreshSpot.fromJsonFontaine(r)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur fontaines: $e');
      return [];
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
