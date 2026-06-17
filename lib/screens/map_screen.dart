import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/fresh_spot.dart';

// Spots reçus depuis HomeScreen — pas de nouvel appel API
class MapScreen extends StatefulWidget {
  final List<FreshSpot> freshSpots;
  const MapScreen({super.key, required this.freshSpots});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  // null = tous les types affichés
  FreshSpotType? _filtreActif;
  FreshSpot? _spotSelectionne;

  static const LatLng _paris = LatLng(48.8566, 2.3522);

  List<FreshSpot> get _spotsFiltres {
    if (_filtreActif == null) return widget.freshSpots;
    return widget.freshSpots.where((s) => s.type == _filtreActif).toList();
  }

  LatLng _centroide(List<FreshSpot> spots) {
    if (spots.isEmpty) return _paris;
    final lat = spots.map((s) => s.latitude).reduce((a, b) => a + b) / spots.length;
    final lon = spots.map((s) => s.longitude).reduce((a, b) => a + b) / spots.length;
    return LatLng(lat, lon);
  }

  void _recentrer() {
    _mapController.move(_centroide(_spotsFiltres), 14);
  }

  // LaunchMode.externalApplication → Google Maps natif, pas une WebView
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
    // Centroïde sur TOUS les spots pour stabiliser la caméra initiale
    final centre = _centroide(widget.freshSpots);

    return Stack(
      children: [

        // ── 1. CARTE ─────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centre,
            initialZoom: 14,
            onTap: (tapPosition, _) => setState(() => _spotSelectionne = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app1',
            ),
            MarkerLayer(
              markers: spots.map((spot) => Marker(
                point: LatLng(spot.latitude, spot.longitude),
                width: 36,
                height: 36,
                child: Tooltip(
                  message: spot.nom,
                  child: GestureDetector(
                    onTap: () => setState(() => _spotSelectionne = spot),
                    child: CircleAvatar(
                      backgroundColor: spot.type.color,
                      radius: 18,
                      child: Icon(spot.type.icon, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),

        // ── 2. FILTRES ────────────────────────────────────────────
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SafeArea(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _filtreActif == null,
                      showCheckmark: false,
                      onSelected: (_) => setState(() {
                        _filtreActif = null;
                        _recentrer();
                      }),
                    ),
                    // Re-tapper le chip actif le désélectionne
                    ...FreshSpotType.values.map((type) => FilterChip(
                      label: Text(type.label),
                      selected: _filtreActif == type,
                      showCheckmark: false,
                      avatar: Icon(type.icon, size: 16, color: type.color),
                      onSelected: (selected) => setState(() {
                        _filtreActif = selected ? type : null;
                        _recentrer();
                      }),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── 3. BOTTOM SHEET ───────────────────────────────────────
        if (_spotSelectionne != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 1.0,
              expand: true,
              builder: (context, scrollController) {
                final spot = _spotSelectionne!;

                return Card(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: ListView(
                    controller: scrollController,
                    children: [

                      // Poignée
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.bordureDsfr,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: spot.type.color,
                          child: Icon(spot.type.icon, color: Colors.white, size: 18),
                        ),
                        title: Text(
                          spot.nom,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(spot.categorie ?? spot.type.label),
                        trailing: Chip(
                          label: Text(spot.estOuvert ? 'Ouvert' : 'Fermé'),
                          backgroundColor: spot.estOuvert ? AppTheme.vertFond : AppTheme.rougeFond,
                          labelStyle: TextStyle(
                            color: spot.estOuvert ? AppTheme.vertDsfr : AppTheme.rougeDsfr,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),

                      const Divider(),

                      _BadgesContextuels(spot: spot),

                      if (spot.adresseFormatee.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppTheme.griseTexteDsfr),
                          title: Text(spot.adresseFormatee),
                        ),

                      if (spot.description.trim().isNotEmpty)
                        ListTile(
                          leading: Icon(
                            spot.type == FreshSpotType.parc ? Icons.forest : Icons.info_outline,
                            color: AppTheme.griseTexteDsfr,
                          ),
                          title: Text(spot.description),
                        ),

                      if (spot.distanceLabel.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.straighten, color: AppTheme.griseTexteDsfr),
                          title: Text(spot.distanceLabel),
                        ),

                      const Divider(),
                      _SectionHoraires(type: spot.type, horaires: spot.horaires),

                      const Divider(),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ActionChip(
                            avatar: const Icon(Icons.directions, size: 18),
                            label: const Text('Itinéraire'),
                            onPressed: () => _ouvrirItineraire(spot),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // ── 4. FAB recentrer ─────────────────────────────────────
        // heroTag explicite — évite le conflit avec d'autres FAB dans le Scaffold
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            heroTag: 'map_recentrer',
            onPressed: _recentrer,
            tooltip: 'Recentrer sur les spots visibles',
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
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
        // Badge canicule en premier — info la plus cruciale pour l'app
        if (spot.caniculeOuverture ?? false) {
          badges.add(_chip('Spécial canicule', Icons.wb_sunny, AppTheme.orangeFond, AppTheme.orangeDsfr));
        }
        if (spot.ouvert24h ?? false) {
          badges.add(_chip('Ouvert la nuit', Icons.nightlight, AppTheme.fondDsfr, AppTheme.bleuRepublique));
        }
        if (spot.ouvertureNocturneEte ?? false) {
          badges.add(_chip('Nocturne été', Icons.bedtime_outlined, AppTheme.fondDsfr, AppTheme.bleuRepublique));
        }
        break;

      case FreshSpotType.equipement:
        if (spot.gratuit == true) {
          badges.add(_chip('Gratuit', Icons.euro_outlined, AppTheme.vertFond, AppTheme.vertDsfr));
        } else if (spot.gratuit == false) {
          badges.add(_chip('Payant', Icons.euro, AppTheme.bordureDsfr, AppTheme.griseTexteDsfr));
        }
        break;

      case FreshSpotType.fontaine:
        if (spot.motifIndispo != null) {
          badges.add(_chip('Hors service · ${spot.motifIndispo}', Icons.warning_amber_outlined, AppTheme.rougeFond, AppTheme.rougeDsfr));
        }
        break;
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 6, children: badges),
    );
  }

  static Widget _chip(String label, IconData icon, Color bg, Color fg) {
    return Chip(
      avatar: Icon(icon, size: 14, color: fg),
      label: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
      backgroundColor: bg,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _SectionHoraires extends StatelessWidget {
  final FreshSpotType type;
  final Map<String, String>? horaires;
  const _SectionHoraires({required this.type, required this.horaires});

  static const List<String> _jours = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.schedule, size: 16, color: AppTheme.griseTexteDsfr),
            SizedBox(width: 6),
            Text("Horaires d'ouverture", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.griseTexteDsfr)),
          ]),
          const SizedBox(height: 8),
          if (type == FreshSpotType.fontaine)
            const Text('Accès libre', style: TextStyle(fontSize: 13, color: AppTheme.titreDsfr))
          else if (horaires == null)
            const Text('Horaires non communiqués', style: TextStyle(fontSize: 13, color: AppTheme.griseTexteDsfr, fontStyle: FontStyle.italic))
          else
            ..._buildGrille(horaires!),
          const SizedBox(height: 4),
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
        child: Row(children: [
          SizedBox(
            width: 90,
            child: Text(jour, style: TextStyle(fontSize: 13, fontWeight: estAujourd ? FontWeight.w700 : FontWeight.w400, color: estAujourd ? AppTheme.bleuRepublique : AppTheme.titreDsfr)),
          ),
          Expanded(
            child: Text(horaire ?? 'Non communiqué', style: TextStyle(fontSize: 13, fontWeight: estAujourd ? FontWeight.w700 : FontWeight.w400, color: horaire != null ? (estAujourd ? AppTheme.bleuRepublique : AppTheme.titreDsfr) : AppTheme.griseTexteDsfr)),
          ),
        ]),
      );
    }).toList();
  }
}
