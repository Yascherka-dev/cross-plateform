import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

// Service responsable de tous les appels à l'API Open-Meteo
// Séparé du modèle pour respecter le principe de responsabilité unique (SRP)
// → le modèle gère la structure des données, le service gère les appels réseau
class WeatherService {

  // Durée maximale avant de re-appeler l'API
  // Open-Meteo met à jour les données "current" toutes les 15 minutes
  static const Duration cacheDuration = Duration(minutes: 15);

  // Stocke le dernier résultat pour éviter des appels inutiles
  WeatherData? _cachedData;
  DateTime? _lastFetch;

  // Méthode principale: récupère les données météo pour une position GPS
  // lat et lon viennent du service de géolocalisation
  Future<WeatherData> fetchWeather(double lat, double lon) async {

    // Vérification du cache: si on a des données récentes (moins de 15 min)
    // on les retourne directement sans appeler l'API
    if (_cachedData != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < cacheDuration) {
        return _cachedData!; // retour depuis le cache
      }
    }

    // Construction de l'URL avec tous les paramètres nécessaires
    // timezone=auto laisse Open-Meteo détecter le fuseau depuis les coords GPS
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      // Données temps réel (mises à jour toutes les 15 min)
      '&current=temperature_2m,apparent_temperature,'
      'relative_humidity_2m,uv_index,weathercode,windspeed_10m'
      // Données horaires pour calculer les pics de la journée
      '&hourly=temperature_2m,uv_index'
      // timezone=auto détecte automatiquement depuis les coordonnées GPS
      '&timezone=auto'
      // On ne récupère qu'aujourd'hui, pas besoin des jours suivants
      '&forecast_days=1'
    );

    // Appel HTTP GET à l'API (await = on attend la réponse avant de continuer)
    final response = await http.get(url);

    // 200 = succès → on parse le JSON et on met en cache
    if (response.statusCode == 200) {
      _cachedData = WeatherData.fromJson(jsonDecode(response.body));
      _lastFetch = DateTime.now();
      return _cachedData!;
    } else {
      // Tout autre code = erreur réseau ou API indisponible
      throw Exception('Erreur API Open-Meteo: ${response.statusCode}');
    }
  }
}