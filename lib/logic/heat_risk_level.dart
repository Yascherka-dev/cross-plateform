// Enumération des 3 niveaux de risque canicule de l'app
// Ces valeurs sont utilisées partout dans l'app pour adapter
// l'interface, les fiches conseils et les filtres de carte
enum HeatRiskLevel { vert, orange, rouge }

// Fonction principale de logique métier de l'app
// Elle calcule le niveau de risque à partir des données météo
// C'est ici qu'on code nos propres règles, sans dépendre d'une API
//
// Les seuils sont optionnels: si Supabase (table heat_thresholds) les fournit,
// ils remplacent les valeurs par défaut — sinon les constantes ci-dessous s'appliquent
HeatRiskLevel calculateHeatRisk({
  required double temp,       // température réelle en °C (temperature_2m)
  required double feelsLike,  // température ressentie (apparent_temperature)
  required int humidity,      // humidité relative en % (relative_humidity_2m)
  required double uvNow,      // indice UV actuel (uv_index current)
  required double peakTemp,   // pic de température sur 24h (max hourly)
  required double peakUv,     // pic UV sur 24h (max hourly)
  // Seuils configurables via Supabase — valeurs par défaut = constantes métier initiales
  required double seuilTempOrange,
  required double seuilTempRouge,
  required double seuilUvOrange,
  required double seuilUvRouge,
  required int    humiditeBoost1,
  required int    humiditeBoost2,
}) {

  // On prend le pire entre température réelle et ressentie
  // Ex: 32° réel mais 35° ressenti → on utilise 35° pour le calcul
  final double refTemp = feelsLike > temp ? feelsLike : temp;

  // Modificateur humidité: au-dessus des seuils, la transpiration
  // refroidit moins bien le corps, ce qui amplifie la dangerosité
  final double humidityBoost = humidity > humiditeBoost2 ? 2.0
                             : humidity > humiditeBoost1 ? 1.0
                             : 0.0;

  // Température effective = ressenti + impact de l'humidité
  final double effectiveTemp = refTemp + humidityBoost;

  // Pour l'UV on compare le niveau actuel avec 50% du pic journalier
  // Si on est en matinée, le pic de 14h compte déjà comme risque futur
  final double refUv = peakUv > 9.0 ? peakUv : uvNow;

  // ROUGE : danger élevé — un seul critère suffit à déclencher l'alerte
  if (effectiveTemp > seuilTempRouge || peakTemp > seuilTempRouge || refUv > seuilUvRouge) {
    return HeatRiskLevel.rouge;
  }

  // ORANGE : vigilance
  // Exemple concret: 23° mais UV à 7 → ORANGE (comme Paris ce matin)
  if (effectiveTemp >= seuilTempOrange || peakTemp >= seuilTempOrange || refUv >= seuilUvOrange) {
    return HeatRiskLevel.orange;
  }

  // VERT : pas de risque particulier, tous les seuils sont sous les limites
  return HeatRiskLevel.vert;
}