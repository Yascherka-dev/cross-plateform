import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/emergency_tile.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _service = SupabaseService();

  late final Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchEmergencyNumbers();
  }

  Future<void> _confirmerAppel(String numero, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.fond,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Appeler le $numero ?',
            textAlign: TextAlign.center,
            style: AppTheme.titre(19),
          ),
          content: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              size: 13,
              color: AppTheme.texteSecondaire,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.separateur,
                      foregroundColor: AppTheme.texteSurface,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: AppTheme.body(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: AppTheme.texteSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.rougeTexte,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text(
                      'Appeler',
                      style: AppTheme.body(
                        size: 14.5,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final uri = Uri(
        scheme: 'tel',
        path: numero.replaceAll(' ', ''),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final numbers = snapshot.hasData
            ? snapshot.data!
            : SupabaseService.emergencyFallback;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingMd,
            AppTheme.spacingLg,
            AppTheme.spacingXxl,
          ),
          children: [
            Text(
              "Numéros d'urgence",
              style: AppTheme.titre(22),
            ),

            const SizedBox(height: 4),

            Text(
              'Touchez un numéro pour appeler',
              style: AppTheme.body(
                size: 12.5,
                color: AppTheme.texteSecondaire,
              ),
            ),

            const SizedBox(height: 16),

            _EmergencyWarningCard(),

            const SizedBox(height: 16),

            for (final number in numbers) ...[
              EmergencyTile(
                data: number,
                onTap: () => _confirmerAppel(
                  number['numero'] as String,
                  number['label'] as String,
                ),
              ),
              const SizedBox(height: 9),
            ],
          ],
        );
      },
    );
  }
}

class _EmergencyWarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.rougeFond,
        borderRadius: BorderRadius.circular(AppTheme.radiusCarteSmall),
        border: Border.all(
          color: AppTheme.urgenceBordure,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_rounded,
            color: AppTheme.fermeTexte,
            size: 19,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'En cas de malaise, confusion ou forte fièvre, appelez le ',
                children: [
                  TextSpan(
                    text: '15',
                    style: AppTheme.body(
                      size: 12,
                      weight: FontWeight.w800,
                      color: AppTheme.urgenceTexte,
                    ),
                  ),
                  const TextSpan(text: ' sans attendre.'),
                ],
              ),
              style: AppTheme.body(
                size: 12,
                weight: FontWeight.w500,
                color: AppTheme.urgenceTexte,
              ),
            ),
          ),
        ],
      ),
    );
  }
}