// Fichier de configuration central de l'app
// Regroupe les constantes OpenData Paris (URLs des datasets, limites) et le
// cache associé. NB : l'URL Open-Meteo vit dans weather_service.dart.

class AppConfig {

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

  // Durée de validité du cache OpenData Paris
  // Les fontaines/parcs ne changent pas souvent → 1h est suffisant
  static const Duration freshSpotCacheDuration = Duration(hours: 1);

  // NOTE — Les seuils de risque (heat_thresholds) et les numéros d'urgence
  // (emergency_numbers) sont désormais lus depuis Supabase, avec un fallback
  // local dans heat_risk_level.dart et supabase_service.emergencyFallback.
  // Les constantes correspondantes ont été retirées d'ici pour éviter un
  // doublon obsolète.
}
