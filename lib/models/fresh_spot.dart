import 'package:flutter/material.dart';

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

  String get colorHex {
    switch (this) {
      case FreshSpotType.fontaine:   return '#0063CB';
      case FreshSpotType.parc:       return '#18753C';
      case FreshSpotType.equipement: return '#009099';
    }
  }

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData get icon {
    switch (this) {
      case FreshSpotType.fontaine:   return Icons.water_drop;
      case FreshSpotType.parc:       return Icons.park;
      case FreshSpotType.equipement: return Icons.ac_unit;
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
  final String? arrondissement;
  final bool estOuvert;
  final double? distance;
  final Map<String, String>? horaires;

  // Champs contextuels — espaces verts
  final bool ouvert24h;
  final bool caniculeOuverture;
  final bool ouvertureNocturneEte;
  final String? categorie;

  // Champs contextuels — équipements
  final bool? gratuit; // null si non applicable

  // Champs contextuels — fontaines
  final String? motifIndispo; // raison si dispo == "NON"

  FreshSpot({
    required this.id,
    required this.nom,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.adresse,
    required this.estOuvert,
    this.arrondissement,
    this.distance,
    this.horaires,
    this.ouvert24h = false,
    this.caniculeOuverture = false,
    this.ouvertureNocturneEte = false,
    this.categorie,
    this.gratuit,
    this.motifIndispo,
  });

  // ── Dataset: ilots-de-fraicheur-espaces-verts-frais ─────────────────────
  factory FreshSpot.fromJsonEspaceVert(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    final bool ouvert24h      = json['ouvert_24h'] == 'Oui';
    final bool ouvertCanicule = json['canicule_ouverture'] == 'Oui';
    final String statut       = json['statut_ouverture'] ?? 'Ouvert';
    final bool estOuvert      = ouvert24h || ouvertCanicule ||
        statut.toLowerCase().contains('ouvert');

    final double ombrage = (json['proportion_vegetation_haute'] ?? 0).toDouble();
    final String ombrageLabel = ombrage > 50
        ? 'Très ombragé'
        : ombrage > 25
            ? 'Modérément ombragé'
            : 'Peu ombragé';

    return FreshSpot(
      id:                    json['identifiant']?.toString() ?? 'ev_unknown',
      nom:                   json['nom'] ?? 'Espace vert',
      type:                  FreshSpotType.parc,
      latitude:              (geo['lat'] ?? 0.0).toDouble(),
      longitude:             (geo['lon'] ?? 0.0).toDouble(),
      description:           ombrageLabel,
      adresse:               json['adresse'] ?? '',
      arrondissement:        json['arrondissement']?.toString(),
      estOuvert:             estOuvert,
      horaires:              _parseHoraires(json),
      ouvert24h:             ouvert24h,
      caniculeOuverture:     ouvertCanicule,
      ouvertureNocturneEte:  json['ouverture_estivale_nocturne'] == 'Oui',
      categorie:             json['categorie']?.toString(),
    );
  }

  // ── Dataset: ilots-de-fraicheur-equipements-activites ───────────────────
  factory FreshSpot.fromJsonEquipement(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    final String statut  = json['statut_ouverture'] ?? '';
    final bool estOuvert = statut.isEmpty ||
        statut.toLowerCase().contains('ouvert');

    final bool estGratuit = json['payant'] == 'Non';

    return FreshSpot(
      id:             json['identifiant']?.toString() ?? 'eq_unknown',
      nom:            json['nom'] ?? 'Équipement frais',
      type:           FreshSpotType.equipement,
      latitude:       (geo['lat'] ?? 0.0).toDouble(),
      longitude:      (geo['lon'] ?? 0.0).toDouble(),
      description:    json['type']?.toString() ?? 'Équipement',
      adresse:        json['adresse'] ?? '',
      arrondissement: json['arrondissement']?.toString(),
      estOuvert:      estOuvert,
      horaires:       _parseHoraires(json),
      gratuit:        estGratuit,
    );
  }

  // ── Dataset: fontaines-a-boire ──────────────────────────────────────────
  factory FreshSpot.fromJsonFontaine(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    final bool estOuvert = json['dispo'] == 'OUI';
    final String motif   = json['motif_ind']?.toString().trim() ?? '';
    final String commune = json['commune']?.toString() ?? '';

    return FreshSpot(
      id:            json['gid']?.toString() ?? 'f_unknown',
      nom:           json['type_objet']?.toString() ?? 'Fontaine',
      type:          FreshSpotType.fontaine,
      latitude:      (geo['lat'] ?? 0.0).toDouble(),
      longitude:     (geo['lon'] ?? 0.0).toDouble(),
      description:   json['modele']?.toString() ?? '',
      adresse:       json['voie']?.toString() ?? '',
      arrondissement: commune.isNotEmpty ? commune : null,
      estOuvert:     estOuvert,
      motifIndispo:  (!estOuvert && motif.isNotEmpty) ? motif : null,
    );
  }

  FreshSpot copyWithDistance(double distanceMetres) {
    return FreshSpot(
      id:                   id,
      nom:                  nom,
      type:                 type,
      latitude:             latitude,
      longitude:            longitude,
      description:          description,
      adresse:              adresse,
      arrondissement:       arrondissement,
      estOuvert:            estOuvert,
      distance:             distanceMetres,
      horaires:             horaires,
      ouvert24h:            ouvert24h,
      caniculeOuverture:    caniculeOuverture,
      ouvertureNocturneEte: ouvertureNocturneEte,
      categorie:            categorie,
      gratuit:              gratuit,
      motifIndispo:         motifIndispo,
    );
  }

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

  static const Map<String, String> _abreviations = {
    'AV':  'Avenue',
    'BD':  'Boulevard',
    'BLD': 'Boulevard',
    'R':   'Rue',
    'PL':  'Place',
    'SQ':  'Square',
    'IMP': 'Impasse',
    'ALL': 'Allée',
    'RPT': 'Rond-Point',
    'PAS': 'Passage',
    'QU':  'Quai',
    'CHE': 'Chemin',
    'CRS': 'Cours',
    'RTE': 'Route',
    'VLA': 'Villa',
  };

  String get adresseFormatee {
    if (adresse.trim().isEmpty) return '';

    var base = adresse.trim().replaceAllMapped(
      RegExp(r'^(\d+)\s+[A-Z]\s+', caseSensitive: false),
      (m) => '${m[1]} ',
    );

    base = base.split(RegExp(r'\s+')).map((mot) {
      if (mot.isEmpty) return mot;
      final cle = mot.toUpperCase();
      if (_abreviations.containsKey(cle)) return _abreviations[cle]!;
      return mot[0].toUpperCase() + mot.substring(1).toLowerCase();
    }).join(' ');

    final arr = _arrondissementFormate;
    return arr != null ? '$base, $arr' : base;
  }

  String? get _arrondissementFormate {
    if (arrondissement == null || arrondissement!.trim().isEmpty) return null;

    final matchCode = RegExp(r'^75(\d{3})$').firstMatch(arrondissement!.trim());
    if (matchCode != null) {
      final n = int.tryParse(matchCode.group(1)!) ?? 0;
      if (n == 0) return null;
      return 'Paris ${n == 1 ? "1er" : "${n}e"}';
    }

    final matchTexte = RegExp(r'(\d+)\s*(?:EME|ER)', caseSensitive: false)
        .firstMatch(arrondissement!);
    if (matchTexte != null) {
      final n = int.tryParse(matchTexte.group(1)!) ?? 0;
      if (n == 0) return null;
      return 'Paris ${n == 1 ? "1er" : "${n}e"}';
    }

    return null;
  }

  String get distanceLabel {
    if (distance == null) return '';
    if (distance! < 1000) return '${distance!.toInt()} m';
    return '${(distance! / 1000).toStringAsFixed(1)} km';
  }
}
