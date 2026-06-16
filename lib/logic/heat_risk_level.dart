// Enumération des 3 niveaux de risque canicule de l'app
// Ces valeurs sont utilisées partout dans l'app pour adapter
// l'interface, les fiches conseils et les filtres de carte
enum HeatRiskLevel { vert, orange, rouge }

// Fonction principale de logique métier de l'app
// Elle calcule le niveau de risque à partir des données météo
// C'est ici qu'on code nos propres règles, sans dépendre d'une API
HeatRiskLevel calculateHeatRisk({
  required double temp,       // température réelle en °C (temperature_2m)
  required double feelsLike,  // température ressentie (apparent_temperature)
  required int humidity,      // humidité relative en % (relative_humidity_2m)
  required double uvNow,      // indice UV actuel (uv_index current)
  required double peakTemp,   // pic de température sur 24h (max hourly)
  required double peakUv,     // pic UV sur 24h (max hourly)
}) {

  // On prend le pire entre température réelle et ressentie
  // Ex: 32° réel mais 35° ressenti → on utilise 35° pour le calcul
  final double refTemp = feelsLike > temp ? feelsLike : temp;

  // Modificateur humidité: au-dessus de 60%, la transpiration
  // refroidit moins bien le corps, ce qui amplifie la dangerosité
  // > 70% → +2°C effectifs / > 60% → +1°C effectifs
  final double humidityBoost = humidity > 70 ? 2.0
                             : humidity > 60 ? 1.0
                             : 0.0;

  // Température effective = ressenti + impact de l'humidité
  final double effectiveTemp = refTemp + humidityBoost;

  // Pour l'UV on compare le niveau actuel avec 50% du pic journalier
  // Si on est en matinée, le pic de 14h compte déjà comme risque futur
 final double refUv = peakUv > 9.0 ? peakUv : uvNow;

  // ROUGE : danger élevé → température effective > 35° OU pic UV > 8
  // L'opérateur OU signifie qu'un seul critère suffit à déclencher l'alerte
  if (effectiveTemp > 35.0 || peakTemp > 35.0 || refUv > 8.0) {
    return HeatRiskLevel.rouge;
  }

  // ORANGE : vigilance → température >= 30° OU pic UV >= 6
  // Exemple concret: 23° mais UV à 7 → ORANGE (comme Paris ce matin)
  if (effectiveTemp >= 30.0 || peakTemp >= 30.0 || refUv >= 6.0) {
    return HeatRiskLevel.orange;
  }

  // VERT : pas de risque particulier, tous les seuils sont sous les limites
  return HeatRiskLevel.vert;
}