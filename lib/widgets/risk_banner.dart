import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/weather_data.dart';

// Bannière principale affichant le niveau de risque et les métriques météo
// C'est le SEUL endroit où les couleurs vert/orange/rouge sont utilisées
class RiskBanner extends StatelessWidget {
  final HeatRiskLevel riskLevel;
  final WeatherData weather;

  const RiskBanner({
    super.key,
    required this.riskLevel,
    required this.weather,
  });

  Color get _color {
    switch (riskLevel) {
      case HeatRiskLevel.vert:   return AppTheme.vertDsfr;
      case HeatRiskLevel.orange: return AppTheme.orangeDsfr;
      case HeatRiskLevel.rouge:  return AppTheme.rougeDsfr;
    }
  }

  String get _label {
    switch (riskLevel) {
      case HeatRiskLevel.vert:   return 'Risque faible';
      case HeatRiskLevel.orange: return 'Vigilance orange';
      case HeatRiskLevel.rouge:  return 'Alerte rouge canicule';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${weather.temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ressenti ${weather.feelsLike.toStringAsFixed(1)}°C '
            '• UV ${weather.uvNow.toStringAsFixed(1)} '
            '• Humidité ${weather.humidity}%',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Pic aujourd'hui: ${weather.peakTemp.toStringAsFixed(1)}°C "
            '• UV max ${weather.peakUv.toStringAsFixed(1)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
