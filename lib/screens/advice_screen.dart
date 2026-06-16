import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../logic/heat_risk_level.dart';
import '../models/advice_card.dart';
import '../services/supabase_service.dart';

// Écran conseils — affiche les fiches adaptées au niveau de risque actuel
// Les fiches et numéros d'urgence viennent de Supabase avec fallback local
// StatefulWidget pour stocker le Future et éviter de relancer l'appel à chaque rebuild
class AdviceScreen extends StatefulWidget {
  final HeatRiskLevel? riskLevel;

  const AdviceScreen({super.key, required this.riskLevel});

  @override
  State<AdviceScreen> createState() => _AdviceScreenState();
}

class _AdviceScreenState extends State<AdviceScreen> {
  final _service = SupabaseService();

  // Future stocké en état pour ne pas le recréer à chaque rebuild
  late final Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    // Fiches + numéros d'urgence chargés en parallèle depuis Supabase
    _dataFuture = Future.wait([
      _service.fetchAdviceCards(),
      _service.fetchEmergencyNumbers(),
    ]);
  }

  // Label lisible du niveau pour le titre de l'écran
  String _getLevelLabel(HeatRiskLevel level) {
    switch (level) {
      case HeatRiskLevel.vert:   return 'Risque faible';
      case HeatRiskLevel.orange: return 'Vigilance orange';
      case HeatRiskLevel.rouge:  return 'Alerte rouge';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cas impossible en pratique: AdviceScreen n'est affiché qu'une fois
    // les données chargées dans HomeScreen, donc riskLevel est toujours non-null
    if (widget.riskLevel == null) {
      return const Center(child: Text('Niveau de risque non disponible'));
    }

    return FutureBuilder<List<dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {

        // État 1: chargement en cours
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.bleuRepublique),
          );
        }

        // Données Supabase ou fallback local si le réseau est inaccessible
        final List<AdviceCard> cards = snapshot.hasData
            ? snapshot.data![0] as List<AdviceCard>
            : allAdviceCards;
        final List<Map<String, dynamic>> numbers = snapshot.hasData
            ? snapshot.data![1] as List<Map<String, dynamic>>
            : _fallbackNumbers;

        // Filtre: une fiche ORANGE apparaît aussi en ROUGE (niveau ≥ fiche)
        // Même logique que getAdviceCardsForLevel() — appliquée à la liste Supabase
        final filtered = cards
            .where((c) => c.niveau.index <= widget.riskLevel!.index)
            .toList();

        // État 2: contenu affiché
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // -----------------------------------------------
            // EN-TÊTE: niveau de risque actuel
            // -----------------------------------------------
            Text(
              'Conseils — ${_getLevelLabel(widget.riskLevel!)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.titreDsfr,
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------
            // FICHES CONSEILS en accordéon (ExpansionTile)
            // Une fiche par Card, dépliable au tap
            // -----------------------------------------------
            ...filtered.map((card) => _AdviceCardTile(card: card)),

            // -----------------------------------------------
            // NUMÉROS D'URGENCE — boutons cliquables qui ouvrent le téléphone
            // Affichés uniquement si la liste n'est pas vide
            // -----------------------------------------------
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
              ...numbers.map((n) => _EmergencyButton(data: n)),
            ],
          ],
        );
      },
    );
  }

  // Numéros d'urgence locaux — utilisés si Supabase est inaccessible (hors ligne)
  static const List<Map<String, dynamic>> _fallbackNumbers = [
    {
      'numero':      '15',
      'label':       'SAMU',
      'description': 'Urgences médicales',
      'ordre':       1,
    },
    {
      'numero':      '18',
      'label':       'Pompiers',
      'description': 'Secours et incendie',
      'ordre':       2,
    },
    {
      'numero':      '3114',
      'label':       'Prévention suicide',
      'description': 'Numéro national de prévention du suicide',
      'ordre':       3,
    },
    {
      'numero':      '112',
      'label':       'Urgences européennes',
      'description': "Numéro européen d'urgence",
      'ordre':       4,
    },
  ];
}

// -----------------------------------------------
// WIDGET: _AdviceCardTile
// Fiche conseil en accordéon — ExpansionTile dans une Card
// Bande colorée à gauche = indicateur visuel du niveau de la fiche
// -----------------------------------------------
class _AdviceCardTile extends StatelessWidget {
  final AdviceCard card;

  const _AdviceCardTile({required this.card});

  // Couleur de la bande latérale selon le niveau de la fiche
  Color _levelColor() {
    switch (card.niveau) {
      case HeatRiskLevel.vert:   return AppTheme.vertDsfr;
      case HeatRiskLevel.orange: return AppTheme.orangeDsfr;
      case HeatRiskLevel.rouge:  return AppTheme.rougeDsfr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        // Bande colorée à gauche = indicateur du niveau
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _levelColor(),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          card.titre,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        // Contenu déplié: liste à puces des conseils
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: card.conseils.map((conseil) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontSize: 14),
                      ),
                      Expanded(
                        child: Text(
                          conseil,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------
// WIDGET: _EmergencyButton
// Carte numéro d'urgence cliquable — ouvre le téléphone via URI tel:
// -----------------------------------------------
class _EmergencyButton extends StatelessWidget {
  final Map<String, dynamic> data;

  const _EmergencyButton({required this.data});

  // Ouvre le composeur téléphonique avec le numéro pré-rempli
  Future<void> _appeler(String numero) async {
    final uri = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final numero = data['numero'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          // Numéro affiché en grand dans un container coloré
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.rougeDsfr.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.rougeDsfr,
                ),
              ),
            ),
          ),
          title: Text(
            data['label'] as String,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(data['description'] as String),
          trailing: const Icon(
            Icons.phone,
            color: AppTheme.rougeDsfr,
          ),
          onTap: () => _appeler(numero),
        ),
      ),
    );
  }
}
