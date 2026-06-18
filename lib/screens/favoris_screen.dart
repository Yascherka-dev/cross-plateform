import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/fresh_spot.dart';
import '../services/auth_service.dart';
import '../services/favoris_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/fresh_spot_tile.dart';
import '../widgets/message_etat.dart';
import '../widgets/round_icon_button.dart';
import 'login_screen.dart';

// Écran listant les favoris de l'utilisateur connecté.
class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _authService = AuthService();
  final _favorisService = FavorisService();

  late Future<List<FreshSpot>> _future;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<List<FreshSpot>> _charger() {
    if (_authService.currentUser == null) return Future.value([]);
    return _favorisService.fetchFavoris();
  }

  Future<void> _refresh() async {
    setState(() => _future = _charger());
    await _future;
  }

  Future<void> _retirer(FreshSpot spot) async {
    try {
      await _favorisService.retirerFavori(spot.id);
      await _refresh();
      if (mounted) afficherSnack(context, 'Retiré des favoris');
    } catch (_) {
      /* erreur silencieuse : la liste reste inchangée */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.fond,
        surfaceTintColor: Colors.transparent,
        title: Text('Mes favoris', style: AppTheme.titre(18)),
      ),
      body: _authService.currentUser == null
          ? _EtatNonConnecte()
          : RefreshIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.surface,
              onRefresh: _refresh,
              child: FutureBuilder<List<FreshSpot>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    );
                  }

                  final favoris = snapshot.data ?? [];
                  if (favoris.isEmpty) return const _EtatVide();

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    itemCount: favoris.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTheme.spacingSm),
                    itemBuilder: (context, i) {
                      final spot = favoris[i];
                      // Tap long pour retirer (raccourci) + bouton cœur dédié.
                      return GestureDetector(
                        // Tap : ouvrir sur la carte (renvoie le spot à HomeScreen).
                        onTap: () => Navigator.pop(context, spot),
                        // Tap long : retirer des favoris.
                        onLongPress: () => _retirer(spot),
                        child: Row(
                          children: [
                            Expanded(child: FreshSpotTile(spot: spot)),
                            const SizedBox(width: AppTheme.spacingSm),
                            RoundIconButton(
                              icon: Icons.favorite_rounded,
                              color: AppTheme.rougeTexte,
                              onTap: () => _retirer(spot),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

// État : utilisateur non connecté.
class _EtatNonConnecte extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXxl),
        child: MessageEtat(
          icon: Icons.favorite_border_rounded,
          message: 'Connectez-vous pour retrouver vos lieux favoris.',
          actionLabel: 'Se connecter',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      ),
    );
  }
}

// État : connecté mais aucun favori.
class _EtatVide extends StatelessWidget {
  const _EtatVide();

  @override
  Widget build(BuildContext context) {
    // ListView pour permettre le pull-to-refresh même quand c'est vide.
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingXxl),
      children: const [
        SizedBox(height: 80),
        MessageEtat(
          icon: Icons.map_rounded,
          message:
              'Aucun favori pour le moment.\n'
              'Explorez la carte et touchez le cœur pour en ajouter.',
        ),
      ],
    );
  }
}
