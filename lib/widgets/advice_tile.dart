import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/advice_card.dart';

// Fiche conseil en accordéon
// La bande latérale gauche colorée est le seul indicateur de niveau
class AdviceTile extends StatelessWidget {
  final AdviceCard card;

  const AdviceTile({super.key, required this.card});

  Color get _levelColor {
    switch (card.niveau) {
      case HeatRiskLevel.vert:   return AppTheme.vertDsfr;
      case HeatRiskLevel.orange: return AppTheme.orangeDsfr;
      case HeatRiskLevel.rouge:  return AppTheme.rougeDsfr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          border: Border(
            left:   BorderSide(color: _levelColor, width: 4),
            bottom: const BorderSide(color: AppTheme.bordureDsfr, width: 1),
          ),
        ),
        child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        title: Text(
          card.titre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.titreDsfr,
          ),
        ),
        iconColor: AppTheme.griseTexteDsfr,
        collapsedIconColor: AppTheme.griseTexteDsfr,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: card.conseils.map((conseil) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14, color: AppTheme.titreDsfr)),
                      Expanded(
                        child: Text(
                          conseil,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.titreDsfr,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
