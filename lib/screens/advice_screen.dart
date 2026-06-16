import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/advice_card.dart';
import '../services/supabase_service.dart';
import '../widgets/advice_tile.dart';
import '../widgets/emergency_tile.dart';

class AdviceScreen extends StatefulWidget {
  final HeatRiskLevel? riskLevel;

  const AdviceScreen({super.key, required this.riskLevel});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> {
  final _service = SupabaseService();

  late final Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([
      _service.fetchAdviceCards(),
      _service.fetchEmergencyNumbers(),
    ]);
  }

  String _getLevelLabel(HeatRiskLevel level) {
    switch (level) {
      case HeatRiskLevel.vert:   return 'Risque faible';
      case HeatRiskLevel.orange: return 'Vigilance orange';
      case HeatRiskLevel.rouge:  return 'Alerte rouge';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.riskLevel == null) {
      return const Center(child: Text('Niveau de risque non disponible'));
    }

    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.bleuRepublique),
          );
        }

        final List<AdviceCard> cards = snapshot.hasData
            ? snapshot.data![0] as List<AdviceCard>
            : allAdviceCards;
        final List<Map<String, dynamic>> numbers = snapshot.hasData
            ? snapshot.data![1] as List<Map<String, dynamic>>
            : SupabaseService.emergencyFallback;

        final filtered = cards
            .where((c) => c.niveau.index <= widget.riskLevel!.index)
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [

            Text(
              'Conseils — ${_getLevelLabel(widget.riskLevel!)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.titreDsfr,
              ),
            ),

            const SizedBox(height: 16),

            ...filtered.map((card) => AdviceTile(card: card)),

            if (numbers.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                "Numéros d'urgence",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.titreDsfr,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: AppTheme.urgenceFond,
                child: Column(
                  children: [
                    for (int i = 0; i < numbers.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      EmergencyTile(data: numbers[i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
