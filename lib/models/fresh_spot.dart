// Enumération des types de points de fraîcheur disponibles dans l'app
// Correspond aux 3 datasets OpenData Paris qu'on interroge
enum FreshSpotType {
  fontaine,    // Dataset fontaines-a-boire (1327 points)
  parc,        // Dataset ilots-de-fraicheur-espaces-verts-frais (986 points)
  equipement,  // Dataset ilots-de-fraicheur-equipements-activites (548 points)
}

// Extension sur FreshSpotType pour les méthodes utilitaires
// directement sur l'enum → évite des switch/case partout dans le code
extension FreshSpotTypeExtension on FreshSpotType {

  // Label affiché dans l'UI (badge, filtre, carte)
  String get label {
    switch (this) {
      case FreshSpotType.fontaine:   return 'Fontaine';
      case FreshSpotType.parc:       return 'Espace vert';
      case FreshSpotType.equipement: return 'Équipement frais';
    }
  }

  // Couleur hexadécimale du marqueur sur la carte — palette DSFR
  String get colorHex {
    switch (this) {
      case FreshSpotType.fontaine:   return '#0063CB'; // bleu DSFR
      case FreshSpotType.parc:       return '#18753C'; // vert DSFR
      case FreshSpotType.equipement: return '#009099'; // teal DSFR
    }
  }
}

// Modèle représentant un point de fraîcheur sur la carte
class FreshSpot {
  final String id;             // identifiant unique
  final String nom;            // nom du lieu
  final FreshSpotType type;    // type de point
  final double latitude;       // coordonnée GPS
  final double longitude;      // coordonnée GPS
  final String description;    // description / catégorie
  final String adresse;        // adresse complète
  final bool estOuvert;        // statut d'ouverture
  final double? distance;      // distance en mètres depuis l'utilisateur
                               // nullable car calculée après la récupération API

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
  });

  // -------------------------------------------------------
  // FACTORY 1: Espaces verts frais
  // Dataset: ilots-de-fraicheur-espaces-verts-frais
  // Champs confirmés par l'API réelle
  // -------------------------------------------------------
  factory FreshSpot.fromJsonEspaceVert(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    // Logique d'ouverture: on combine 3 champs disponibles dans ce dataset
    // ouvert_24h = "Oui" → toujours ouvert
    // canicule_ouverture = "Oui" → ouvert spécialement pendant canicule
    // statut_ouverture peut être null → on le traite comme ouvert par défaut
    final bool ouvert24h       = json['ouvert_24h'] == 'Oui';
    final bool ouvertCanicule  = json['canicule_ouverture'] == 'Oui';
    final String statut        = json['statut_ouverture'] ?? 'Ouvert';
    final bool estOuvert       = ouvert24h || ouvertCanicule ||
        statut.toLowerCase().contains('ouvert');

    // proportion_vegetation_haute indique le % d'ombrage
    // On l'utilise dans la description pour informer l'utilisateur
    final double ombrage = (json['proportion_vegetation_haute'] ?? 0).toDouble();
    final String ombrageLabel = ombrage > 50
        ? 'Très ombragé'
        : ombrage > 25
            ? 'Modérément ombragé'
            : 'Peu ombragé';

    return FreshSpot(
      id:          json['identifiant']?.toString() ?? 'ev_unknown',
      nom:         json['nom'] ?? 'Espace vert',            // champ réel = "nom"
      type:        FreshSpotType.parc,
      latitude:    (geo['lat'] ?? 0.0).toDouble(),
      longitude:   (geo['lon'] ?? 0.0).toDouble(),
      description: '$ombrageLabel • ${json['categorie'] ?? json['type'] ?? ''}',
      adresse:     json['adresse'] ?? '',
      estOuvert:   estOuvert,
    );
  }

  // -------------------------------------------------------
  // FACTORY 2: Équipements frais
  // Dataset: ilots-de-fraicheur-equipements-activites
  // Champs confirmés par l'API réelle
  // -------------------------------------------------------
  factory FreshSpot.fromJsonEquipement(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    // statut_ouverture peut être null dans ce dataset
    // On considère ouvert par défaut si pas d'info
    final String statut  = json['statut_ouverture'] ?? '';
    final bool estOuvert = statut.isEmpty ||
        statut.toLowerCase().contains('ouvert');

    // payant = "Oui"/"Non" → on l'affiche dans la description
    final String payant = json['payant'] == 'Non' ? 'Gratuit' : 'Payant';

    return FreshSpot(
      id:          json['identifiant']?.toString() ?? 'eq_unknown',
      nom:         json['nom'] ?? 'Équipement frais',    // champ réel = "nom"
      type:        FreshSpotType.equipement,
      latitude:    (geo['lat'] ?? 0.0).toDouble(),
      longitude:   (geo['lon'] ?? 0.0).toDouble(),
      description: '${json['type'] ?? 'Équipement'} • $payant',
      adresse:     json['adresse'] ?? '',
      estOuvert:   estOuvert,
    );
  }

  // -------------------------------------------------------
  // FACTORY 3: Fontaines à boire
  // Dataset: fontaines-a-boire
  // Champs confirmés par l'API réelle
  // -------------------------------------------------------
  factory FreshSpot.fromJsonFontaine(Map<String, dynamic> json) {
    final geo = json['geo_point_2d'] ?? {};

    // dispo = "OUI"/"NON" → champ réel pour le statut des fontaines
    // motif_ind = raison de l'indisponibilité (ex: "APP A REPARER")
    final bool estOuvert   = json['dispo'] == 'OUI';
    final String motif     = json['motif_ind'] ?? '';
    final String descMotif = !estOuvert && motif.isNotEmpty
        ? ' • $motif'
        : '';

    // voie = nom de la rue (pas de champ "nom" dans ce dataset)
    // type_objet = "BORNE_FONTAINE", "FONTAINE_WALLACE"...
    // modele = modèle de la fontaine (ex: "GHM Ville de Paris")
    final String typeObjet = json['type_objet'] ?? 'Fontaine';
    final String voie      = json['voie'] ?? '';
    final String commune   = json['commune'] ?? '';

    return FreshSpot(
      id:          json['gid']?.toString() ?? 'f_unknown', // champ réel = "gid"
      nom:         typeObjet,                               // pas de nom propre
      type:        FreshSpotType.fontaine,
      latitude:    (geo['lat'] ?? 0.0).toDouble(),
      longitude:   (geo['lon'] ?? 0.0).toDouble(),
      description: '${json['modele'] ?? ''}$descMotif',
      adresse:     '$voie, $commune',
      estOuvert:   estOuvert,
    );
  }

  // Crée une copie avec la distance calculée (immutabilité)
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
    );
  }

  // Distance formatée pour l'UI: 150 → "150 m" / 1500 → "1.5 km"
  String get distanceLabel {
    if (distance == null) return '';
    if (distance! < 1000) return '${distance!.toInt()} m';
    return '${(distance! / 1000).toStringAsFixed(1)} km';
  }
}