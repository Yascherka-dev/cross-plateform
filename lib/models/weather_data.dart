// Modèle de données météo de l'app
// Représente une réponse complète de l'API Open-Meteo
// Contient à la fois les données actuelles et les pics journaliers
class WeatherData {
  final double temperature;  // température actuelle en °C
  final double feelsLike;    // température ressentie en °C
  final int humidity;        // humidité relative en %
  final double uvNow;        // indice UV au moment de l'appel
  final double peakTemp;     // température max prévue sur la journée
  final double peakUv;       // indice UV max prévu sur la journée
  final double windSpeed;    // vitesse du vent en km/h
  final DateTime horodatage; // moment de la récupération des données

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.uvNow,
    required this.peakTemp,
    required this.peakUv,
    required this.windSpeed,
    required this.horodatage,
  });

  // Factory constructor: transforme le JSON brut de l'API
  // en objet WeatherData exploitable dans l'app
  factory WeatherData.fromJson(Map<String, dynamic> json) {

    // On isole le bloc "current" qui contient les données temps réel
    final current = json['current'];

    // On extrait la liste des températures horaires sur 24h
    // List<double>.from() convertit le JSON array en liste Dart typée
    final List<double> hourlyTemp = List<double>.from(
      json['hourly']['temperature_2m'],
    );

    // Même chose pour les UV horaires
    // Le ?? 0.0 gère le cas où une valeur UV serait nulle dans le JSON
    // (ex: la nuit, l'API retourne null au lieu de 0)
    final List<double> hourlyUv = List<double>.from(
      json['hourly']['uv_index'].map((v) => (v ?? 0.0).toDouble()),
    );

    return WeatherData(
      temperature: current['temperature_2m'].toDouble(),
      feelsLike:   current['apparent_temperature'].toDouble(),
      humidity:    current['relative_humidity_2m'].toInt(),
      uvNow:       (current['uv_index'] ?? 0.0).toDouble(),
      windSpeed:   current['windspeed_10m'].toDouble(),

      // reduce() parcourt toute la liste et garde la valeur max
      // C'est le pic de température prévu sur les 24h de la journée
      peakTemp: hourlyTemp.reduce((a, b) => a > b ? a : b),

      // Même logique pour le pic UV journalier
      peakUv: hourlyUv.reduce((a, b) => a > b ? a : b),

      // On horodate la récupération pour gérer le cache (15 min max)
      horodatage: DateTime.now(),
    );
  }
}