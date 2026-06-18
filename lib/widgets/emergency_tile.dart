import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_theme.dart';

class EmergencyTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const EmergencyTile({
    super.key,
    required this.data,
    this.onTap,
  });

  Future<void> _appeler(String numero) async {
    final uri = Uri(
      scheme: 'tel',
      path: numero.replaceAll(' ', ''),
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color get _color {
    switch (data['numero']) {
      case '15':
        return AppTheme.rougeTexte;

      case '18':
        return AppTheme.orangeTexte;

      case '112':
        return AppTheme.fontaineTexte;

      case '114':
        return AppTheme.equipementTexte;

      default:
        return AppTheme.parcTexte;
    }
  }

  Color get _background {
    switch (data['numero']) {
      case '15':
        return AppTheme.rougeFond;

      case '18':
        return AppTheme.orangeFond;

      case '112':
        return AppTheme.fontaineFond;

      case '114':
        return AppTheme.equipementFond;

      default:
        return AppTheme.parcFond;
    }
  }

  IconData get _icon {
    switch (data['numero']) {
      case '15':
        return Icons.medical_services_rounded;

      case '18':
        return Icons.local_fire_department_rounded;

      case '112':
        return Icons.sos_rounded;

      case '114':
        return Icons.hearing_rounded;

      default:
        return Icons.support_agent_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final numero = data['numero'] as String;

    return InkWell(
      borderRadius: BorderRadius.circular(
        AppTheme.radiusCarte,
      ),
      onTap: onTap ?? () => _appeler(numero),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(
            AppTheme.radiusCarte,
          ),
          border: Border.all(
            color: AppTheme.bordure,
          ),
          boxShadow: AppTheme.ombreBase,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _icon,
                color: _color,
                size: 22,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        numero,
                        style: AppTheme.titre(19).copyWith(
                          color: AppTheme.textePrincipal,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          data['label'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppTheme.texteSurface,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 2),

                  Text(
                    data['description'] as String,
                    style: AppTheme.body(
                      size: 12,
                      color: AppTheme.texteSecondaire,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.fond,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.call_rounded,
                color: AppTheme.texteSurface,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}