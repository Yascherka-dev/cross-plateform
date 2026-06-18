import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/advice_card.dart';
import 'icon_pastille.dart';

const Set<String> _illustrationsAvecTexte = {
  'signes de vigilance',
  'numeros durgence',
  'que faire en cas de coup de chaleur',
  'signes dinsolation',
};

String _normaliserTitre(String s) {
  var r = s.toLowerCase().trim();

  const accents = {
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'à': 'a',
    'â': 'a',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'û': 'u',
    'ù': 'u',
    'ç': 'c',
  };

  accents.forEach((k, v) => r = r.replaceAll(k, v));
  r = r.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
  r = r.replaceAll(RegExp(r'\s+'), ' ').trim();

  return r;
}

class AdviceTile extends StatelessWidget {
  final AdviceCard card;

  const AdviceTile({super.key, required this.card});

  Color get _levelColor {
    switch (card.niveau) {
      case HeatRiskLevel.vert:
        return AppTheme.vertTexte;
      case HeatRiskLevel.orange:
        return AppTheme.orangeTexte;
      case HeatRiskLevel.rouge:
        return AppTheme.rougeTexte;
    }
  }

  Color get _levelBackground {
    switch (card.niveau) {
      case HeatRiskLevel.vert:
        return AppTheme.vertFond;
      case HeatRiskLevel.orange:
        return AppTheme.orangeFond;
      case HeatRiskLevel.rouge:
        return AppTheme.rougeFond;
    }
  }

  IconData get _icon {
    switch (card.niveau) {
      case HeatRiskLevel.vert:
        return Icons.local_drink_rounded;
      case HeatRiskLevel.orange:
        return Icons.health_and_safety_rounded;
      case HeatRiskLevel.rouge:
        return Icons.emergency_rounded;
    }
  }

  List<Widget> _contenuDeplie() {
    final imageUrl = card.imageUrl;
    final aImage = imageUrl != null && imageUrl.isNotEmpty;
    final avecTexte = _illustrationsAvecTexte.contains(
      _normaliserTitre(card.titre),
    );
    final montrerTexte = !aImage || !avecTexte;

    return [
      if (aImage)
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            0,
            AppTheme.spacingLg,
            montrerTexte ? AppTheme.spacingMd : AppTheme.spacingLg,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCarteSmall),
            child: Image.network(
              imageUrl,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return Container(
                  height: 170,
                  color: AppTheme.fond,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(color: _levelColor),
                );
              },
              errorBuilder: (_, _, _) {
                if (montrerTexte) return const SizedBox.shrink();
                return _listeConseils();
              },
            ),
          ),
        ),
      if (montrerTexte) _listeConseils(),
    ];
  }

  Widget _listeConseils() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        0,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: card.conseils.map((conseil) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: AppTheme.body(
                    size: 14,
                    weight: FontWeight.w700,
                    color: _levelColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    conseil,
                    style: AppTheme.body(
                      size: 13,
                      weight: FontWeight.w500,
                      color: AppTheme.texteSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCarte),
        border: Border.all(color: AppTheme.bordure),
        boxShadow: AppTheme.ombreBase,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: _levelBackground,
            highlightColor: _levelBackground,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingSm,
            ),
            childrenPadding: EdgeInsets.zero,
            iconColor: AppTheme.texteSecondaire,
            collapsedIconColor: AppTheme.texteSecondaire,
            title: Row(
              children: [
                IconPastille(
                  icon: _icon,
                  color: _levelColor,
                  background: _levelBackground,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    card.titre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: AppTheme.textePrincipal,
                    ),
                  ),
                ),
              ],
            ),
            children: _contenuDeplie(),
          ),
        ),
      ),
    );
  }
}
