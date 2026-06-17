import '../logic/heat_risk_level.dart';

// Modèle représentant une fiche conseil premiers secours
// Ces fiches sont stockées LOCALEMENT dans l'app, sans appel API
// C'est la logique métier pure → répond au retour du prof
class AdviceCard {
  final String id;                  // identifiant unique de la fiche
  final String titre;               // titre affiché dans l'accordéon
  final HeatRiskLevel niveau;       // niveau à partir duquel la fiche s'affiche
  final List<String> conseils;      // liste des conseils à afficher
  final List<String> numerosUrgence; // numéros à appeler si besoin

  const AdviceCard({
    required this.id,
    required this.titre,
    required this.niveau,
    required this.conseils,
    required this.numerosUrgence,
  });

  // Désérialisation depuis la table Supabase `advice_cards`
  // Le champ `niveau` est stocké en texte ('vert'/'orange'/'rouge')
  // et converti en enum via le nom du membre
  factory AdviceCard.fromJson(Map<String, dynamic> json) {
    return AdviceCard(
      id:             json['id']    as String,
      titre:          json['titre'] as String,
      niveau:         HeatRiskLevel.values.firstWhere(
                        (e) => e.name == json['niveau'],
                        orElse: () => HeatRiskLevel.vert,
                      ),
      conseils:       List<String>.from(json['conseils'] as List),
      numerosUrgence: List<String>.from(json['numeros_urgence'] as List),
    );
  }
}

// Liste complète des fiches conseils de l'app
// Classées par niveau de risque croissant
// const = compile-time constant, jamais rechargé depuis le réseau
const List<AdviceCard> allAdviceCards = [

  // ---------- NIVEAU VERT ----------
  AdviceCard(
    id: 'vert_hydratation',
    titre: 'Bien s\'hydrater',
    niveau: HeatRiskLevel.vert,
    conseils: [
      'Buvez au moins 1,5L d\'eau par jour',
      'Évitez l\'alcool et les boissons sucrées',
      'Préférez l\'eau fraîche (pas glacée)',
    ],
    numerosUrgence: [],
  ),

  // ---------- NIVEAU ORANGE ----------
  AdviceCard(
    id: 'orange_signes',
    titre: 'Signes de vigilance',
    niveau: HeatRiskLevel.orange,
    conseils: [
      'Évitez les sorties entre 12h et 16h',
      'Portez un chapeau et des vêtements légers',
      'Rafraîchissez-vous avec un brumisateur',
      'Vérifiez l\'état des personnes âgées autour de vous',
    ],
    numerosUrgence: [],
  ),

  AdviceCard(
    id: 'orange_uv',
    titre: 'Protection solaire',
    niveau: HeatRiskLevel.orange,
    conseils: [
      'Appliquez une crème solaire indice 50+',
      'Renouvelez l\'application toutes les 2h',
      'Portez des lunettes de soleil à protection UV',
      'Restez à l\'ombre dès que possible',
    ],
    numerosUrgence: [],
  ),

  // ---------- NIVEAU ROUGE ----------
  AdviceCard(
    id: 'rouge_insolation',
    titre: 'Signes d\'insolation',
    niveau: HeatRiskLevel.rouge,
    conseils: [
      'Maux de tête intenses et persistants',
      'Nausées ou vomissements',
      'Peau rouge, chaude et sèche (absence de transpiration)',
      'Confusion, désorientation ou perte de conscience',
      'Température corporelle > 40°C',
    ],
    numerosUrgence: ['15', '18'],
  ),

  AdviceCard(
    id: 'rouge_gestes',
    titre: 'Que faire en cas de coup de chaleur',
    niveau: HeatRiskLevel.rouge,
    conseils: [
      '1. Appelez le 15 (SAMU) immédiatement',
      '2. Allongez la personne à l\'ombre',
      '3. Aspergez-la d\'eau fraîche (pas froide)',
      '4. Ventilez-la avec un éventail ou un journal',
      '5. Ne lui donnez rien à boire si elle est inconsciente',
    ],
    numerosUrgence: ['15', '18'],
  ),

  AdviceCard(
    id: 'rouge_urgences',
    titre: 'Numéros d\'urgence',
    niveau: HeatRiskLevel.rouge,
    conseils: [
      '15 → SAMU (urgences médicales)',
      '18 → Pompiers',
      '112 → Numéro européen d\'urgence',
    ],
    numerosUrgence: ['15', '18', '112'],
  ),
];

// Fonction utilitaire: filtre les fiches selon le niveau de risque actuel
// Une fiche ORANGE s'affiche aussi en ROUGE (niveau >= niveau de la fiche)
List<AdviceCard> getAdviceCardsForLevel(HeatRiskLevel currentLevel) {
  return allAdviceCards.where((card) {
    // Convertit l'enum en index numérique pour comparer les niveaux
    // vert=0, orange=1, rouge=2
    return card.niveau.index <= currentLevel.index;
  }).toList();
}