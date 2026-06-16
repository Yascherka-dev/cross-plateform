import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/weather_data.dart';

class RiskBanner extends StatelessWidget {
  final HeatRiskLevel riskLevel;
  final WeatherData weather;

  const RiskBanner({
    super.key,
    required this.riskLevel,
    required this.weather,
  });

  Color get _fond {
    switch (riskLevel) {
      case HeatRiskLevel.vert:   return AppTheme.vertFond;
      case HeatRiskLevel.orange: return AppTheme.orangeFond;
      case HeatRiskLevel.rouge:  return AppTheme.rougeFond;
    }
  }

  Color get _texte {
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
        color: _fond,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _texte, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label,
            style: TextStyle(
              color: _texte,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${weather.temperature.toStringAsFixed(1)}°C',
            style: TextStyle(
              color: _texte,
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ressenti ${weather.feelsLike.toStringAsFixed(1)}°C '
            '• UV ${weather.uvNow.toStringAsFixed(1)} '
            '• Humidité ${weather.humidity}%',
            style: TextStyle(color: _texte, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            "Pic aujourd'hui: ${weather.peakTemp.toStringAsFixed(1)}°C "
            '• UV max ${weather.peakUv.toStringAsFixed(1)}',
            style: TextStyle(color: _texte, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
