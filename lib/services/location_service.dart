import 'package:geolocator/geolocator.dart';

class LocationService {

  Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'La localisation est désactivée. '
        'Activez-la dans les paramètres de votre téléphone.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          "Permission de localisation refusée. Autorisez l'app dans vos paramètres.",
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permission de localisation refusée définitivement. '
        'Allez dans Paramètres > Applications > SOS Canicule.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double distanceTo({
    required double userLat,
    required double userLon,
    required double spotLat,
    required double spotLon,
  }) {
    return Geolocator.distanceBetween(userLat, userLon, spotLat, spotLon);
  }
}
