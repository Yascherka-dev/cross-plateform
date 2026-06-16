import 'package:geolocator/geolocator.dart';

// Service de géolocalisation de l'app
// Gère toutes les permissions et la récupération de la position GPS
// Séparé du WeatherService pour respecter le principe SRP:
// → un service = une responsabilité
class LocationService {

  // Méthode principale: retourne la position GPS actuelle de l'utilisateur
  // C'est un Future car la récupération GPS est asynchrone
  // (on attend que le téléphone nous donne les coordonnées)
  Future<Position> getCurrentPosition() async {

    // ÉTAPE 1: Vérifier si le GPS est activé sur le téléphone
    // Si l'utilisateur a désactivé la localisation dans ses paramètres,
    // on ne peut rien faire → on lève une exception explicite
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'La localisation est désactivée. '
        'Activez-la dans les paramètres de votre téléphone.'
      );
    }

    // ÉTAPE 2: Vérifier les permissions de l'app
    // Sur iOS et Android, l'utilisateur doit autoriser l'app
    // à accéder à sa position
    LocationPermission permission = await Geolocator.checkPermission();

    // Si la permission n'a jamais été demandée → on la demande maintenant
    // Une popup système s'affichera sur le téléphone de l'utilisateur
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      // Si l'utilisateur refuse → on ne peut pas continuer
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Permission de localisation refusée. '
          'Autorisez l\'app dans vos paramètres.'
        );
      }
    }

    // Si l'utilisateur a définitivement refusé (ne plus demander)
    // requestPermission() ne s'affichera plus → on redirige vers les paramètres
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permission de localisation refusée définitivement. '
        'Allez dans Paramètres > Applications > SOS Canicule.'
      );
    }

    // ÉTAPE 3: Toutes les permissions sont OK → on récupère la position
    // LocationAccuracy.high = précision GPS maximale (quelques mètres)
    // C'est important pour trouver les points d'eau les plus proches
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Méthode utilitaire: calcule la distance en mètres entre
  // la position de l'utilisateur et un point de fraîcheur
  // Utilisée pour afficher "à 150m" sur les cartes des FreshSpots
  double distanceTo({
    required double userLat,
    required double userLon,
    required double spotLat,
    required double spotLon,
  }) {
    // Geolocator.distanceBetween() utilise la formule de Haversine
    // qui tient compte de la courbure de la Terre pour être précis
    return Geolocator.distanceBetween(
      userLat,
      userLon,
      spotLat,
      spotLon,
    );
  }
}