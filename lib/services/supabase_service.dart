import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/advice_card.dart';

// Service responsable de la lecture des données distantes dans Supabase
// Trois tables: advice_cards, heat_thresholds, emergency_numbers
// Chaque méthode a un fallback local si le réseau est inaccessible
class SupabaseService {
  // Client singleton fourni par supabase_flutter après Supabase.initialize()
  final _client = Supabase.instance.client;

  // Récupère les fiches conseils depuis la table `advice_cards`
  // Triées par le champ `ordre` pour respecter l'ordre d'affichage
  // Fallback: les fiches hardcodées dans advice_card.dart
  Future<List<AdviceCard>> fetchAdviceCards() async {
    try {
      final data = await _client
          .from('advice_cards')
          .select()
          .order('ordre');

      return (data as List)
          .map((json) => AdviceCard.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Supabase advice_cards indisponible, fallback local: $e');
      // Retourne les fiches locales (toujours disponibles, même hors ligne)
      return allAdviceCards;
    }
  }

  // Récupère les seuils de risque depuis la table `heat_thresholds`
  // Retourne une Map keyed par niveau ('orange' | 'rouge') pour un accès direct
  // Fallback: valeurs identiques aux constantes dans heat_risk_level.dart
  Future<Map<String, Map<String, dynamic>>> fetchHeatThresholds() async {
    try {
      final data = await _client
          .from('heat_thresholds')
          .select();

      return {
        for (final row in data as List)
          row['niveau'] as String: Map<String, dynamic>.from(row as Map),
      };
    } catch (e) {
      debugPrint('Supabase heat_thresholds indisponible, fallback local: $e');
      // Valeurs correspondant exactement aux seuils dans heat_risk_level.dart
      return {
        'orange': {
          'seuil_temp': 30.0,
          'seuil_uv':   6.0,
          'humidite_boost_1': 60,
          'humidite_boost_2': 70,
        },
        'rouge': {
          'seuil_temp': 35.0,
          'seuil_uv':   8.0,
          'humidite_boost_1': 60,
          'humidite_boost_2': 70,
        },
      };
    }
  }

  // Récupère les numéros d'urgence depuis la table `emergency_numbers`
  // Triés par le champ `ordre`
  // Fallback: les 4 numéros essentiels définis localement
  Future<List<Map<String, dynamic>>> fetchEmergencyNumbers() async {
    try {
      final data = await _client
          .from('emergency_numbers')
          .select()
          .order('ordre');

      return List<Map<String, dynamic>>.from(
        (data as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (e) {
      debugPrint('Supabase emergency_numbers indisponible, fallback local: $e');
      return [
        {
          'numero':      '15',
          'label':       'SAMU',
          'description': 'Urgences médicales',
          'ordre':       1,
        },
        {
          'numero':      '18',
          'label':       'Pompiers',
          'description': 'Secours et incendie',
          'ordre':       2,
        },
        {
          'numero':      '3114',
          'label':       'Prévention suicide',
          'description': 'Numéro national de prévention du suicide',
          'ordre':       3,
        },
        {
          'numero':      '112',
          'label':       'Urgences européennes',
          'description': 'Numéro européen d\'urgence',
          'ordre':       4,
        },
      ];
    }
  }
}
