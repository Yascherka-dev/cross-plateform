import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';
import '../widgets/emergency_tile.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Affiche une confirmation avant de lancer l'appel
  Future<void> _confirmerAppel(String numero, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Appel d'urgence"),
        content: Text('Appeler le $numero — $label ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Appeler',
              style: const TextStyle(color: AppTheme.rougeDsfr, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final uri = Uri(scheme: 'tel', path: numero);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
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
          padding: const EdgeInsets.all(16),
          children: [

            const Text(
              "Numéros d'urgence",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.titreDsfr,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              color: AppTheme.urgenceFond,
              child: Column(
                children: [
                  for (int i = 0; i < numbers.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    EmergencyTile(
                      data: numbers[i],
                      onTap: () => _confirmerAppel(
                        numbers[i]['numero'] as String,
                        numbers[i]['label'] as String,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          ],
        );
      },
    );
  }
}
