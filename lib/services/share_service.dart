import 'package:share_plus/share_plus.dart';

import '../models/fresh_spot.dart';

// Partage un lieu de fraîcheur via la feuille de partage native.
// Réutilisé depuis la carte (bottom sheet) et la liste des favoris.
// L'adresse peut être absente (un favori est dénormalisé) : on l'omet alors.
Future<void> partagerSpot(FreshSpot spot) async {
  final adresse = spot.adresseFormatee;
  final entete = adresse.isNotEmpty
      ? '${spot.nom} - ${spot.type.label} - $adresse'
      : '${spot.nom} - ${spot.type.label}';

  final texte =
      '$entete\n'
      '📍 Lien Google Maps: https://www.google.com/maps/dir/?api=1'
      '&destination=${spot.latitude},${spot.longitude}\n'
      'Trouvé sur SOS Canicule 🌡️';

  await SharePlus.instance.share(ShareParams(text: texte));
}
