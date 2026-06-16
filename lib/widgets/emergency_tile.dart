import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';

// Ligne d'un numéro d'urgence cliquable
// Conçu pour être utilisé dans une Column avec Divider entre items
class EmergencyTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const EmergencyTile({super.key, required this.data});

  Future<void> _appeler(String numero) async {
    final uri = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final numero = data['numero'] as String;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 52,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.urgenceFond,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.bleuRepublique, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          numero,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppTheme.bleuRepublique,
          ),
        ),
      ),
      title: Text(
        data['label'] as String,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.titreDsfr,
        ),
      ),
      subtitle: Text(
        data['description'] as String,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.griseTexteDsfr,
        ),
      ),
      trailing: const Icon(Icons.phone_outlined, color: AppTheme.bleuRepublique, size: 20),
      onTap: () => _appeler(numero),
    );
  }
}
