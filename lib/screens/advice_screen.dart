import 'package:flutter/material.dart';
import '../logic/heat_risk_level.dart';

// Écran conseils — reçoit le niveau de risque actuel
// pour filtrer les fiches selon la dangerosité
class AdviceScreen extends StatelessWidget {
  final HeatRiskLevel? riskLevel;

  const AdviceScreen({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Conseils niveau ${riskLevel?.name ?? "inconnu"} — à venir'),
      ),
    );
  }
}