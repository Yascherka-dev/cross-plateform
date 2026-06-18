import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/advice_card.dart';
import '../services/supabase_service.dart';
import '../widgets/advice_tile.dart';

class AdviceScreen extends StatefulWidget {
  final HeatRiskLevel? riskLevel;
  const AdviceScreen({super.key, required this.riskLevel});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> {
  final _service = SupabaseService();
  late final Future<List<AdviceCard>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAdviceCards();
  }

  // En-tête de section coloré selon le niveau ; mis en avant si c'est le niveau actuel
  Widget _enteteSection(String label, HeatRiskLevel niveau) {
    final estActif = niveau == widget.riskLevel;
    final Color fond;
    final Color texte;
    switch (niveau) {
      case HeatRiskLevel.vert:
        fond = AppTheme.vertFond;
        texte = AppTheme.vertTexte;
      case HeatRiskLevel.orange:
        fond = AppTheme.orangeFond;
        texte = AppTheme.orangeTexte;
      case HeatRiskLevel.rouge:
        fond = AppTheme.rougeFond;
        texte = AppTheme.rougeTexte;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: estActif ? fond : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.body(
              size: 15,
              weight: FontWeight.w700,
              color: estActif ? texte : AppTheme.texteSecondaire,
            ),
          ),
          if (estActif) ...[
            const SizedBox(width: AppTheme.spacingSm),
            Chip(
              label: const Text('Niveau actuel'),
              labelStyle: AppTheme.label(size: 11, color: texte),
              backgroundColor: fond,
              side: BorderSide.none,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdviceCard>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }

        final cards = snapshot.hasData ? snapshot.data! : allAdviceCards;
        final vert = cards.where((c) => c.niveau == HeatRiskLevel.vert).toList();
        final orange =
            cards.where((c) => c.niveau == HeatRiskLevel.orange).toList();
        final rouge =
            cards.where((c) => c.niveau == HeatRiskLevel.rouge).toList();

        return ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            Text(
              'Conseils de prévention',
              style: AppTheme.titre(18),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            if (vert.isNotEmpty) ...[
              _enteteSection('Toujours utile', HeatRiskLevel.vert),
              ...vert.map((card) => AdviceTile(card: card)),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            if (orange.isNotEmpty) ...[
              _enteteSection('Si vigilance orange', HeatRiskLevel.orange),
              ...orange.map((card) => AdviceTile(card: card)),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            if (rouge.isNotEmpty) ...[
              _enteteSection('Si alerte rouge', HeatRiskLevel.rouge),
              ...rouge.map((card) => AdviceTile(card: card)),
            ],
          ],
        );
      },
    );
  }
}
