import 'package:flutter/widgets.dart';

import '../config/app_theme.dart';

enum HeatRiskLevel { vert, orange, rouge }

// Style visuel associé à un niveau de risque (couleur, fond, libellé).
// Source unique de vérité partagée par RiskBanner et l'aperçu météo Welcome.
class HeatRiskStyle {
  final Color couleur;
  final Color fond;
  final String label;

  const HeatRiskStyle({
    required this.couleur,
    required this.fond,
    required this.label,
  });
}

extension HeatRiskLevelStyle on HeatRiskLevel {
  HeatRiskStyle get style => switch (this) {
    HeatRiskLevel.vert => const HeatRiskStyle(
      couleur: AppTheme.vertTexte,
      fond: AppTheme.vertFond,
      label: 'Pas de vigilance',
    ),
    HeatRiskLevel.orange => const HeatRiskStyle(
      couleur: AppTheme.orangeTexte,
      fond: AppTheme.orangeFond,
      label: 'Vigilance orange',
    ),
    HeatRiskLevel.rouge => const HeatRiskStyle(
      couleur: AppTheme.rougeTexte,
      fond: AppTheme.rougeFond,
      label: 'Alerte rouge',
    ),
  };
}

// Calcule le niveau de risque à partir des conditions météo ACTUELLES uniquement.
//
// Ancien comportement : peakTemp et peakUv entraient dans la décision,
// ce qui causait "Alerte rouge" à 26°C parce que le pic prévu plus tard
// dans la journée franchissait le seuil — incohérent avec ce que l'utilisateur vit.
//
// Nouveau comportement : seuls temp, feelsLike, humidity et uvNow décident du niveau.
// peakTemp et peakUv restent des paramètres requis pour l'affichage informatif
// dans home_screen.dart ("Pic aujourd'hui : X°C") mais n'influencent plus le calcul.
//
// Les seuils viennent de Supabase (table heat_thresholds) ; les valeurs named params
// en sont les valeurs injectées — pas de hardcoding ici.
HeatRiskLevel calculateHeatRisk({
  required double temp,       // température réelle en °C
  required double feelsLike,  // température ressentie
  required int    humidity,   // humidité relative en %
  required double uvNow,      // indice UV actuel
  required double peakTemp,   // pic journalier — affichage uniquement
  required double peakUv,     // pic UV journalier — affichage uniquement
  required double seuilTempOrange,
  required double seuilTempRouge,
  required double seuilUvOrange,
  required double seuilUvRouge,
  required int    humiditeBoost1,
  required int    humiditeBoost2,
}) {
  // Pire entre température réelle et ressentie
  final double refTemp = feelsLike > temp ? feelsLike : temp;

  // Humidité élevée réduit l'efficacité de la transpiration → +1 ou +2°C effectifs
  final double humidityBoost = humidity > humiditeBoost2 ? 2.0
                             : humidity > humiditeBoost1 ? 1.0
                             : 0.0;

  final double effectiveTemp = refTemp + humidityBoost;

  // ROUGE : danger immédiat
  if (effectiveTemp > seuilTempRouge || uvNow > seuilUvRouge) {
    return HeatRiskLevel.rouge;
  }

  // ORANGE : vigilance
  if (effectiveTemp >= seuilTempOrange || uvNow >= seuilUvOrange) {
    return HeatRiskLevel.orange;
  }

  return HeatRiskLevel.vert;
}
