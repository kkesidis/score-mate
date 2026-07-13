import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../models/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenScreenState();
}

class _SettingsScreenScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ScoreDen'),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.settings,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            elevation: 0,
            child: ValueListenableBuilder<String>(
              valueListenable: appLanguageNotifier,
              builder: (context, currentLanguageCode, child) {
                return ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(
                    AppLocalizations.of(context)!.language,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.languageName,
                        style: const TextStyle(
                          color: AppTheme.primaryForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () {
                    context.go('/settings/language');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}