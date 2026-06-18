import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/fresh_spot.dart';

class FreshSpotTile extends StatelessWidget {
  final FreshSpot spot;

  const FreshSpotTile({
    super.key,
    required this.spot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCarteSmall),
        border: Border.all(color: AppTheme.bordure),
        boxShadow: AppTheme.ombreBase,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: spot.type.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
            ),
            child: Icon(
              spot.type.icon,
              color: spot.type.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: AppTheme.textePrincipal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  spot.type.label,
                  style: AppTheme.body(
                    size: 11.5,
                    weight: FontWeight.w500,
                    color: AppTheme.texteSecondaire,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                spot.distanceLabel,
                style: AppTheme.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppTheme.texteSurface,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: spot.estOuvert
                      ? AppTheme.ouvertFond
                      : AppTheme.fermeFond,
                  borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                ),
                child: Text(
                  spot.estOuvert ? 'Ouvert' : 'Fermé',
                  style: AppTheme.label(
                    size: 10,
                    color: spot.estOuvert
                        ? AppTheme.ouvertTexte
                        : AppTheme.fermeTexte,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}