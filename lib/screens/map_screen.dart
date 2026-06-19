import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../models/fresh_spot.dart';
import '../services/auth_service.dart';
import '../services/favoris_service.dart';
import '../services/share_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/icon_pastille.dart';
import '../widgets/round_icon_button.dart';
import 'login_screen.dart';

class MapScreen extends StatefulWidget {
  final List<FreshSpot> freshSpots;
  final List<String> sourcesEnEchec;
  final VoidCallback? onRetry;
  // Si fourni, ouvre directement le détail de ce spot et centre la carte dessus.
  final FreshSpot? spotInitial;

  const MapScreen({
    super.key,
    required this.freshSpots,
    this.sourcesEnEchec = const [],
    this.onRetry,
    this.spotInitial,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  String? _filtreActif;
  FreshSpot? _spotSelectionne;

  static const LatLng _paris = LatLng(48.8566, 2.3522);

  @override
  void initState() {
    super.initState();
    // Ouverture directe sur un spot précis (depuis l'accueil ou les favoris).
    _focusSpot(widget.spotInitial);
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si le MapScreen est réutilisé (ex. déjà sur l'onglet Carte) et qu'un
    // nouveau spot est demandé, initState ne se rejoue pas : on réagit ici.
    if (widget.spotInitial != oldWidget.spotInitial) {
      _focusSpot(widget.spotInitial);
    }
  }

  // Retrouve le spot COMPLET chargé sur la carte (avec adresse/horaires/badges)
  // à partir d'un spot potentiellement partiel (un favori est dénormalisé).
  // Repli sur le spot fourni s'il n'est pas dans la liste chargée.
  FreshSpot _spotComplet(FreshSpot spot) {
    return widget.freshSpots.firstWhere(
      (s) => s.id == spot.id,
      orElse: () => spot,
    );
  }

  // Centre la carte sur un spot et ouvre SON bottom sheet — le même
  // (_SpotBottomSheet via _spotSelectionne) que lors d'un tap sur un marqueur.
  // Appelé depuis initState et didUpdateWidget : un build() suit dans les deux
  // cas, donc pas besoin de setState (qui déclencherait un avertissement).
  void _focusSpot(FreshSpot? spot) {
    if (spot == null) return;
    final complet = _spotComplet(spot);
    _spotSelectionne = complet;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(LatLng(complet.latitude, complet.longitude), 15);
    });
  }

  List<FreshSpot> get _spotsFiltres {
    switch (_filtreActif) {
      case null:
        return widget.freshSpots;
      case 'piscines':
        return widget.freshSpots.where((s) => s.estPiscineOuBaignade).toList();
      default:
        return widget.freshSpots
            .where((s) => s.type.name == _filtreActif)
            .toList();
    }
  }

  LatLng _centroide(List<FreshSpot> spots) {
    if (spots.isEmpty) return _paris;

    final lat =
        spots.map((s) => s.latitude).reduce((a, b) => a + b) / spots.length;
    final lon =
        spots.map((s) => s.longitude).reduce((a, b) => a + b) / spots.length;

    return LatLng(lat, lon);
  }

  void _recentrer() {
    _mapController.move(_centroide(_spotsFiltres), 14);
  }

  // Applique un filtre puis recentre la carte sur les spots correspondants.
  void _appliquerFiltre(String? value) {
    setState(() => _filtreActif = value);
    _recentrer();
  }

  Future<void> _ouvrirItineraire(FreshSpot spot) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${spot.latitude},${spot.longitude}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spotsFiltres;
    final centre = widget.spotInitial != null
        ? LatLng(widget.spotInitial!.latitude, widget.spotInitial!.longitude)
        : _centroide(widget.freshSpots);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centre,
            initialZoom: 14,
            onTap: (_, _) => setState(() => _spotSelectionne = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app1',
            ),
            MarkerLayer(
              markers: spots.map((spot) {
                final color = spot.type.color;

                return Marker(
                  point: LatLng(spot.latitude, spot.longitude),
                  width: 38,
                  height: 38,
                  child: Tooltip(
                    message: spot.nom,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _spotSelectionne = _spotComplet(spot)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: AppTheme.ombreImportante,
                        ),
                        child: Icon(
                          spot.type.icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              children: [
                if (widget.sourcesEnEchec.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _BanniereDonnees(
                      sources: widget.sourcesEnEchec,
                      onRetry: widget.onRetry,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                _BarreFiltres(
                  filtreActif: _filtreActif,
                  onFiltre: _appliquerFiltre,
                ),
              ],
            ),
          ),
        ),

        if (_spotSelectionne != null)
          _SpotBottomSheet(
            spot: _spotSelectionne!,
            ouvrirItineraire: _ouvrirItineraire,
          ),

        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'map_recentrer',
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.accent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.bordure),
            ),
            onPressed: _recentrer,
            tooltip: 'Recentrer sur les spots visibles',
            child: const Icon(Icons.my_location_rounded),
          ),
        ),
      ],
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color iconColor;
  final VoidCallback onTap;

  const _MapFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppTheme.textePrincipal : AppTheme.surface;
    final foreground = selected ? Colors.white : AppTheme.texteSurface;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
            border: Border.all(
              color: selected ? AppTheme.textePrincipal : AppTheme.bordure,
            ),
            boxShadow: AppTheme.ombreBase,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.body(
                  size: 12.5,
                  weight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotBottomSheet extends StatefulWidget {
  final FreshSpot spot;
  final Future<void> Function(FreshSpot spot) ouvrirItineraire;

  const _SpotBottomSheet({required this.spot, required this.ouvrirItineraire});

  @override
  State<_SpotBottomSheet> createState() => _SpotBottomSheetState();
}

class _SpotBottomSheetState extends State<_SpotBottomSheet> {
  final _favorisService = FavorisService();

  bool _estFavori = false;
  bool _verifEnCours = true; // tant qu'on n'a pas lu l'état initial

  FreshSpot get spot => widget.spot;
  Color get _color => spot.type.color;
  Color get _background => spot.type.background;
  IconData get _icon => spot.type.icon;

  @override
  void initState() {
    super.initState();
    _chargerEtatFavori();
  }

  Future<void> _chargerEtatFavori() async {
    // Non connecté : pas de favori, on s'arrête là (pas d'appel réseau).
    if (AuthService().currentUser == null) {
      setState(() => _verifEnCours = false);
      return;
    }
    try {
      final favori = await _favorisService.estFavori(spot.id);
      if (mounted) {
        setState(() {
          _estFavori = favori;
          _verifEnCours = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _verifEnCours = false);
    }
  }

  // Toggle favori avec UI optimiste + SnackBar de confirmation.
  Future<void> _toggleFavori() async {
    if (AuthService().currentUser == null) {
      _inviterConnexion();
      return;
    }

    final ancien = _estFavori;
    setState(() => _estFavori = !ancien); // optimiste

    try {
      if (ancien) {
        await _favorisService.retirerFavori(spot.id);
      } else {
        await _favorisService.ajouterFavori(spot);
      }
      _snack(ancien ? 'Retiré des favoris' : 'Ajouté aux favoris');
    } catch (_) {
      if (mounted) setState(() => _estFavori = ancien); // rollback
      _snack('Action impossible. Réessayez.');
    }
  }

  // Partage texte (fonctionne sans connexion).
  Future<void> _partager() => partagerSpot(spot);

  void _inviterConnexion() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text(
          'Connectez-vous pour enregistrer vos lieux de fraîcheur favoris.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    afficherSnack(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.fond,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppTheme.ombreImportante,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6, bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.poignee,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  IconPastille(
                    icon: _icon,
                    color: _color,
                    background: _background,
                    size: 48,
                    radius: 14,
                    iconSize: 24,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.nom,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.titre(17),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spot.sousTitre,
                          style: AppTheme.body(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppTheme.texteSecondaire,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _OpenBadge(isOpen: spot.estOuvert),
                ],
              ),

              const SizedBox(height: 12),

              // Actions : favori + partage
              Row(
                children: [
                  RoundIconButton(
                    icon: _estFavori
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _estFavori
                        ? AppTheme.rougeTexte
                        : AppTheme.texteSurface,
                    tooltip: _estFavori
                        ? 'Retirer des favoris'
                        : 'Ajouter aux favoris',
                    onTap: _verifEnCours ? null : _toggleFavori,
                  ),
                  const SizedBox(width: 10),
                  RoundIconButton(
                    icon: Icons.share_rounded,
                    color: AppTheme.texteSurface,
                    tooltip: 'Partager',
                    onTap: _partager,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _BadgesContextuels(spot: spot),

              const Divider(),

              const SizedBox(height: 14),

              if (spot.adresseFormatee.isNotEmpty)
                _InfoLine(
                  icon: Icons.location_on_rounded,
                  text: spot.adresseFormatee,
                ),

              if (spot.description.trim().isNotEmpty)
                _InfoLine(
                  icon: spot.type == FreshSpotType.parc
                      ? Icons.forest_rounded
                      : Icons.info_rounded,
                  text: spot.description,
                ),

              if (spot.distanceLabel.isNotEmpty)
                _InfoLine(
                  icon: Icons.near_me_rounded,
                  text: 'À ${spot.distanceLabel} de votre position',
                ),

              _SectionHoraires(type: spot.type, horaires: spot.horaires),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => widget.ouvrirItineraire(spot),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Itinéraire'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Barre horizontale de filtres de la carte (chips générés depuis une liste).
class _BarreFiltres extends StatelessWidget {
  final String? filtreActif;
  final void Function(String?) onFiltre;

  const _BarreFiltres({required this.filtreActif, required this.onFiltre});

  @override
  Widget build(BuildContext context) {
    // (libellé, icône, couleur, valeur de filtre)
    final filtres =
        <({String label, IconData icon, Color couleur, String? valeur})>[
          (
            label: 'Tous',
            icon: Icons.apps_rounded,
            couleur: AppTheme.texteSecondaire,
            valeur: null,
          ),
          (
            label: 'Parcs',
            icon: Icons.park_rounded,
            couleur: AppTheme.parcTexte,
            valeur: FreshSpotType.parc.name,
          ),
          (
            label: 'Fontaines',
            icon: Icons.water_drop_rounded,
            couleur: AppTheme.fontaineTexte,
            valeur: FreshSpotType.fontaine.name,
          ),
          (
            label: 'Climatisés',
            icon: Icons.ac_unit_rounded,
            couleur: AppTheme.equipementTexte,
            valeur: FreshSpotType.climatise.name,
          ),
          (
            label: 'Piscines',
            icon: Icons.pool_rounded,
            couleur: AppTheme.equipementTexte,
            valeur: 'piscines',
          ),
        ];

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filtres.map((f) {
          return _MapFilterChip(
            label: f.label,
            icon: f.icon,
            selected: filtreActif == f.valeur,
            iconColor: f.couleur,
            onTap: () => onFiltre(f.valeur),
          );
        }).toList(),
      ),
    );
  }
}

class _OpenBadge extends StatelessWidget {
  final bool isOpen;

  const _OpenBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppTheme.ouvertTexte : AppTheme.fermeTexte;
    final bg = isOpen ? AppTheme.ouvertFond : AppTheme.fermeFond;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Text(
        isOpen ? 'Ouvert' : 'Fermé',
        style: AppTheme.label(
          size: 10.5,
          color: color,
          weight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppTheme.iconeDiscrete),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
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
  }
}

class _BanniereDonnees extends StatelessWidget {
  final List<String> sources;
  final VoidCallback? onRetry;

  const _BanniereDonnees({required this.sources, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppTheme.orangeFond,
        borderRadius: BorderRadius.circular(AppTheme.radiusCarteSmall),
        border: Border.all(color: AppTheme.bordure),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, size: 18, color: AppTheme.orangeTexte),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Certaines données sont momentanément indisponibles (${sources.join(', ')}).',
              style: AppTheme.body(size: 12, color: AppTheme.texteSurface),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Réessayer',
                style: AppTheme.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppTheme.orangeTexte,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgesContextuels extends StatelessWidget {
  final FreshSpot spot;

  const _BadgesContextuels({required this.spot});

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    switch (spot.type) {
      case FreshSpotType.parc:
        if (spot.caniculeOuverture ?? false) {
          badges.add(
            _chip(
              'Spécial canicule',
              Icons.wb_sunny_rounded,
              AppTheme.orangeFond,
              AppTheme.orangeTexte,
            ),
          );
        }
        if (spot.ouvert24h ?? false) {
          badges.add(
            _chip(
              'Ouvert la nuit',
              Icons.nightlight_round,
              AppTheme.fontaineFond,
              AppTheme.fontaineTexte,
            ),
          );
        }
        if (spot.ouvertureNocturneEte ?? false) {
          badges.add(
            _chip(
              'Nocturne été',
              Icons.bedtime_rounded,
              AppTheme.fontaineFond,
              AppTheme.fontaineTexte,
            ),
          );
        }
        break;

      case FreshSpotType.climatise:
      case FreshSpotType.piscine:
        if (spot.gratuit == true) {
          badges.add(
            _chip(
              'Gratuit',
              Icons.euro_rounded,
              AppTheme.vertFond,
              AppTheme.vertTexte,
            ),
          );
        } else if (spot.gratuit == false) {
          badges.add(
            _chip(
              'Payant',
              Icons.euro_rounded,
              AppTheme.separateur,
              AppTheme.texteSecondaire,
            ),
          );
        }
        break;

      case FreshSpotType.fontaine:
        if (spot.motifIndispo != null) {
          badges.add(
            _chip(
              'Hors service · ${spot.motifIndispo}',
              Icons.warning_rounded,
              AppTheme.rougeFond,
              AppTheme.rougeTexte,
            ),
          );
        }
        break;
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(spacing: 8, runSpacing: 6, children: badges),
    );
  }

  static Widget _chip(String label, IconData icon, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.label(size: 12, color: fg, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionHoraires extends StatelessWidget {
  final FreshSpotType type;
  final Map<String, String>? horaires;

  const _SectionHoraires({required this.type, required this.horaires});

  static const List<String> _jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(
            icon: Icons.schedule_rounded,
            text: type == FreshSpotType.fontaine
                ? 'Accès libre'
                : horaires == null
                ? 'Horaires non communiqués'
                : "Horaires d'ouverture",
          ),
          if (type != FreshSpotType.fontaine && horaires != null)
            ..._buildGrille(horaires!),
        ],
      ),
    );
  }

  List<Widget> _buildGrille(Map<String, String> h) {
    final aujourdHui = _jours[DateTime.now().weekday - 1];

    return _jours.map((jour) {
      final horaire = h[jour];
      final estAujourd = jour == aujourdHui;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                jour,
                style: AppTheme.body(
                  size: 13,
                  weight: estAujourd ? FontWeight.w800 : FontWeight.w500,
                  color: estAujourd ? AppTheme.accent : AppTheme.texteSurface,
                ),
              ),
            ),
            Expanded(
              child: Text(
                horaire ?? 'Non communiqué',
                style: AppTheme.body(
                  size: 13,
                  weight: estAujourd ? FontWeight.w800 : FontWeight.w500,
                  color: horaire != null
                      ? estAujourd
                            ? AppTheme.accent
                            : AppTheme.texteSurface
                      : AppTheme.texteSecondaire,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
