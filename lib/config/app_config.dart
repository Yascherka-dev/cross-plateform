// Fichier de configuration central de l'app
// Toutes les URLs, clés et constantes sont ici
// → si une URL change, on ne modifie qu'un seul endroit

class AppConfig {

  // API OPEN-METEO
  // -------------------------
  // MAJ des data "current" toutes les 15 minutes
  static const String openMeteoBaseUrl =
      'https://api.open-meteo.com/v1/forecast';

  // Paramètres fixes demandés à chaque appel Open-Meteo
  // latitude et longitude sont ajoutés dynamiquement dans WeatherService
  static const String openMeteoParams =
      '&current=temperature_2m,apparent_temperature,'
      'relative_humidity_2m,uv_index,weathercode,windspeed_10m'
      '&hourly=temperature_2m,uv_index'
      '&timezone=auto'
      '&forecast_days=1';

  // -------------------------
  // API OPENDATA PARIS — Îlots de fraîcheur
  // -------------------------
  // Gratuite, pas de clé API nécessaire
  // 3 datasets complémentaires qui forment ensemble la carte des îlots de fraîcheur
  static const String openDataParisBaseUrl =
      'https://opendata.paris.fr/api/explore/v2.1/catalog/datasets';

  // DATASET 1: Espaces verts frais (parcs et jardins ombragés)
  // Classés par % de végétation haute → indique le niveau d'ombre attendu
  // Contient aussi les ouvertures nocturnes pendant les canicules
  static const String espacesVertsFraisDataset =
      '$openDataParisBaseUrl/ilots-de-fraicheur-espaces-verts-frais/records';

  // DATASET 2: Équipements et activités frais
  // Piscines, bibliothèques, musées climatisés, bains-douches,
  // mairies, salles canicule, terrains de boules ombragés...
  static const String equipementsFraisDataset =
      '$openDataParisBaseUrl/ilots-de-fraicheur-equipements-activites/records';

  // DATASET 3: Fontaines à boire
  // Points d'eau potable, fontaines Wallace, brumisateurs
  static const String fontainesDataset =
      '$openDataParisBaseUrl/fontaines-a-boire/records';

  // Nombre max de résultats par appel
  // 100 couvre largement les points autour de l'utilisateur
  static const int openDataLimit = 100;

  // -------------------------
  // CACHE
  // -------------------------
  // Durée de validité du cache météo
  // Open-Meteo met à jour les données "current" toutes les 15 min
  static const Duration weatherCacheDuration = Duration(minutes: 15);

  // Durée de validité du cache OpenData Paris
  // Les fontaines/parcs ne changent pas souvent → 1h est suffisant
  static const Duration freshSpotCacheDuration = Duration(hours: 1);

  // -------------------------
  // NUMÉROS D'URGENCE
  // -------------------------
  // Centralisés ici pour pouvoir les modifier facilement
  static const String numeroSamu              = '15';
  static const String numeroPompiers          = '18';
  static const String numeroUrgencesSociales  = '3114';

  // -------------------------
  // SEUILS HEATRISKLEVEL
  // -------------------------
  // Centralisés ici pour être cohérents entre la logique métier
  // et l'affichage des légendes dans l'UI
  static const double seuilOrangeTemp = 30.0;
  static const double seuilRougeTemp  = 35.0;
  static const double seuilOrangeUv   = 6.0;
  static const double seuilRougeUv    = 8.0;
  static const int    seuilHumidite1  = 60; // +1°C effectif
  static const int    seuilHumidite2  = 70; // +2°C effectif
}