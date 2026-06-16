import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/fresh_spot.dart';

// Ligne d'un point de fraîcheur dans une liste
// Conçu pour être utilisé dans une Column avec Divider entre items
class FreshSpotTile extends StatelessWidget {
  final FreshSpot spot;

  const FreshSpotTile({super.key, required this.spot});

  IconData get _icon {
    switch (spot.type) {
      case FreshSpotType.fontaine:   return Icons.water_drop_outlined;
      case FreshSpotType.parc:       return Icons.park_outlined;
      case FreshSpotType.equipement: return Icons.ac_unit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(_icon, color: AppTheme.bleuRepublique, size: 22),
      title: Text(
        spot.nom,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.titreDsfr,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${spot.type.label} · ${spot.estOuvert ? "Ouvert" : "Fermé"}',
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.griseTexteDsfr,
        ),
      ),
      trailing: Text(
        spot.distanceLabel,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.griseTexteDsfr,
        ),
      ),
    );
  }
}
