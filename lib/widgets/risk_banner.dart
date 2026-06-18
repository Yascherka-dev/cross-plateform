import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/weather_data.dart';

class RiskBanner extends StatelessWidget {
  final HeatRiskLevel riskLevel;
  final WeatherData weather;
  // compact = version réduite (Welcome) : température + niveau + fond coloré,
  // sans les lignes de détail (ressenti / UV / humidité / pic).
  final bool compact;

  const RiskBanner({
    super.key,
    required this.riskLevel,
    required this.weather,
    this.compact = false,
  });

  // Mapping niveau → style centralisé dans heat_risk_level.dart (source unique).
  Color get _riskColor => riskLevel.style.couleur;
  Color get _riskBg => riskLevel.style.fond;
  String get _label => riskLevel.style.label;

  String get _title => switch (riskLevel) {
        HeatRiskLevel.vert => 'Chaleur modérée',
        HeatRiskLevel.orange => 'Forte chaleur',
        HeatRiskLevel.rouge => 'Canicule extrême',
      };

  String get _subtitle => switch (riskLevel) {
        HeatRiskLevel.vert => 'Conditions normales sur Paris aujourd’hui.',
        HeatRiskLevel.orange => 'Pic de chaleur attendu en après-midi.',
        HeatRiskLevel.rouge => 'Restez au frais et hydratez-vous régulièrement.',
      };

  String get _severity => switch (riskLevel) {
        HeatRiskLevel.vert => 'Faible',
        HeatRiskLevel.orange => 'Élevée',
        HeatRiskLevel.rouge => 'Extrême',
      };

  double get _intensity => switch (riskLevel) {
        HeatRiskLevel.vert => 0.30,
        HeatRiskLevel.orange => 0.60,
        HeatRiskLevel.rouge => 0.88,
      };

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact() : _buildComplet();
  }

  // Version réduite pour WelcomeScreen : impact visuel (fond coloré + grosse
  // température + niveau), Paris explicite, pas de lignes de détail.
  Widget _buildCompact() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: _riskBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusHero),
        border: Border.all(color: AppTheme.bordure),
        boxShadow: AppTheme.ombreImportante,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VIGILANCE MÉTÉO', style: AppTheme.sectionLabel()),
              _RiskBadge(
                label: _label,
                color: _riskColor,
                backgroundColor: AppTheme.surface,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: CustomPaint(
                  painter: _RiskGaugePainter(
                    progress: _intensity,
                    color: _riskColor,
                  ),
                  child: Center(
                    child: Text(
                      '${weather.temperature.round()}°',
                      style: AppTheme.titre(34),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title, style: AppTheme.titre(20)),
                    const SizedBox(height: 4),
                    Text(
                      'Paris · aujourd’hui',
                      style: AppTheme.body(
                        size: 12.5,
                        color: AppTheme.texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusHero),
        border: Border.all(color: AppTheme.bordure),
        boxShadow: AppTheme.ombreImportante,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header vigilance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VIGILANCE MÉTÉO',
                style: AppTheme.sectionLabel(),
              ),
              _RiskBadge(
                label: _label,
                color: _riskColor,
                backgroundColor: _riskBg,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Jauge température
              SizedBox(
                width: 108,
                height: 108,
                child: CustomPaint(
                  painter: _RiskGaugePainter(
                    progress: _intensity,
                    color: _riskColor,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${weather.temperature.round()}°',
                        style: AppTheme.titre(32),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'RESSENTI ${weather.feelsLike.round()}°',
                        style: AppTheme.label(
                          size: 10,
                          color: AppTheme.texteSecondaire,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // Infos risque
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: AppTheme.titre(19),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: AppTheme.body(
                        size: 12.5,
                        color: AppTheme.texteSecondaire,
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INTENSITÉ',
                          style: AppTheme.label(
                            size: 10,
                            color: AppTheme.texteTertiaire,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _severity,
                          style: AppTheme.label(
                            size: 11,
                            color: _riskColor,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _intensity,
                        minHeight: 4,
                        backgroundColor: AppTheme.separateur,
                        valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 14),

          // Stats météo
          Row(
            children: [
              Expanded(
                child: _WeatherStat(
                  label: 'Humidité',
                  value: '${weather.humidity}%',
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _WeatherStat(
                  label: 'Indice UV',
                  value: weather.uvNow.toStringAsFixed(1),
                ),
              ),
              const _VerticalDivider(),
              Expanded(
                child: _WeatherStat(
                  label: "Pic aujourd'hui",
                  value: '${weather.peakTemp.round()}°',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _RiskBadge({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.label(
              size: 11.5,
              color: color,
              weight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final String label;
  final String value;

  const _WeatherStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.label(
            size: 10.5,
            color: AppTheme.texteSecondaire,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTheme.body(
            size: 16,
            weight: FontWeight.w800,
            color: AppTheme.texteSurface,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppTheme.separateur,
    );
  }
}

class _RiskGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _RiskGaugePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) - 5;

    final basePaint = Paint()
      ..color = AppTheme.separateur
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, basePaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}