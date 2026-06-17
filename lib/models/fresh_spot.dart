enum FreshSpotType {
  fontaine,
  parc,
  equipement,
}

extension FreshSpotTypeExtension on FreshSpotType {
  String get label {
    switch (this) {
      case FreshSpotType.fontaine:   return 'Fontaine';
      case FreshSpotType.parc:       return 'Espace vert';
      case FreshSpotType.equipement: return 'Équipement frais';
    }
  }

  // Palette DSFR
  String get colorHex {
    switch (this) {
      case FreshSpotType.fontaine:   return '#0063CB';
      case FreshSpotType.parc:       return '#18753C';
      case FreshSpotType.equipement: return '#009099';
    }
  }
}

class FreshSpot {
  final String id;
  final String nom;
  final FreshSpotType type;
  final double latitude;
  final double longitude;
  final String description;
  final String adresse;
  final bool estOuvert;
  final double? distance;              // calculée après récupération API
  final Map<String, String>? horaires; // null pour fontaines ou si tous les jours vides

  FreshSpot({
    required this.id,
    required this.nom,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.adresse,
    required this.estOuvert,
    this.distance,
    this.horaires,
  });

  // ── Dataset: ilots-de-fraicheur-espaces-verts-frais ─────────────────────
  factory FreshSpot.fromJsonEspaceVert(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    // Ouverture: 3 champs combinés — ouvert_24h, canicule_ouverture, statut_ouverture
    final bool ouvert24h      = json['ouvert_24h'] == 'Oui';
    final bool ouvertCanicule = json['canicule_ouverture'] == 'Oui';
    final String statut       = json['statut_ouverture'] ?? 'Ouvert';
    final bool estOuvert      = ouvert24h || ouvertCanicule ||
        statut.toLowerCase().contains('ouvert');

    // proportion_vegetation_haute → % d'ombrage
    final double ombrage = (json['proportion_vegetation_haute'] ?? 0).toDouble();
    final String ombrageLabel = ombrage > 50
        ? 'Très ombragé'
        : ombrage > 25
            ? 'Modérément ombragé'
            : 'Peu ombragé';

    return FreshSpot(
      id:          json['identifiant']?.toString() ?? 'ev_unknown',
      nom:         json['nom'] ?? 'Espace vert',
      type:        FreshSpotType.parc,
      latitude:    (geo['lat'] ?? 0.0).toDouble(),
      longitude:   (geo['lon'] ?? 0.0).toDouble(),
      description: '$ombrageLabel • ${json['categorie'] ?? json['type'] ?? ''}',
      adresse:     json['adresse'] ?? '',
      estOuvert:   estOuvert,
      horaires:    _parseHoraires(json),
    );
  }

  // ── Dataset: ilots-de-fraicheur-equipements-activites ───────────────────
  factory FreshSpot.fromJsonEquipement(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    // statut_ouverture souvent null → ouvert par défaut
    final String statut  = json['statut_ouverture'] ?? '';
    final bool estOuvert = statut.isEmpty ||
        statut.toLowerCase().contains('ouvert');

    final String payant = json['payant'] == 'Non' ? 'Gratuit' : 'Payant';

    return FreshSpot(
      id:          json['identifiant']?.toString() ?? 'eq_unknown',
      nom:         json['nom'] ?? 'Équipement frais',
      type:        FreshSpotType.equipement,
      latitude:    (geo['lat'] ?? 0.0).toDouble(),
      longitude:   (geo['lon'] ?? 0.0).toDouble(),
      description: '${json['type'] ?? 'Équipement'} • $payant',
      adresse:     json['adresse'] ?? '',
      estOuvert:   estOuvert,
      horaires:    _parseHoraires(json), // souvent null en pratique
    );
  }

  // ── Dataset: fontaines-a-boire ──────────────────────────────────────────
  factory FreshSpot.fromJsonFontaine(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    // dispo = "OUI"/"NON" ; motif_ind = raison de l'indisponibilité
    final bool estOuvert   = json['dispo'] == 'OUI';
    final String motif     = json['motif_ind'] ?? '';
    final String descMotif = !estOuvert && motif.isNotEmpty ? ' • $motif' : '';

    // voie + commune remplacent un champ "adresse" absent de ce dataset
    final String typeObjet = json['type_objet'] ?? 'Fontaine';
    final String voie      = json['voie'] ?? '';
    final String commune   = json['commune'] ?? '';

    return FreshSpot(
      id:          json['gid']?.toString() ?? 'f_unknown',
      nom:         typeObjet,
      type:        FreshSpotType.fontaine,
      latitude:    (geo['lat'] ?? 0.0).toDouble(),
      longitude:   (geo['lon'] ?? 0.0).toDouble(),
      description: '${json['modele'] ?? ''}$descMotif',
      adresse:     '$voie, $commune',
      estOuvert:   estOuvert,
    );
  }

  FreshSpot copyWithDistance(double distanceMetres) {
    return FreshSpot(
      id:          id,
      nom:         nom,
      type:        type,
      latitude:    latitude,
      longitude:   longitude,
      description: description,
      adresse:     adresse,
      estOuvert:   estOuvert,
      distance:    distanceMetres,
      horaires:    horaires,
    );
  }

  // Filtre les jours null ou vides ; retourne null si aucun jour renseigné
  static Map<String, String>? _parseHoraires(Map<String, dynamic> json) {
    final jours = {
      'Lundi':    json['horaires_lundi'],
      'Mardi':    json['horaires_mardi'],
      'Mercredi': json['horaires_mercredi'],
      'Jeudi':    json['horaires_jeudi'],
      'Vendredi': json['horaires_vendredi'],
      'Samedi':   json['horaires_samedi'],
      'Dimanche': json['horaires_dimanche'],
    };
    final remplis = Map<String, String>.fromEntries(
      jours.entries
          .where((e) => e.value != null && (e.value as String).trim().isNotEmpty)
          .map((e) => MapEntry(e.key, e.value as String)),
    );
    return remplis.isEmpty ? null : remplis;
  }

  // "150 m" ou "1.5 km"
  String get distanceLabel {
    if (distance == null) return '';
    if (distance! < 1000) return '${distance!.toInt()} m';
    return '${(distance! / 1000).toStringAsFixed(1)} km';
  }
}
