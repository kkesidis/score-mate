import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final List<String> _supportedLanguages = ['en', 'el'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ScoreDen'),
            const SizedBox(height: 2),
            Text(
              l10n.language, 
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
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: _supportedLanguages.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final String targetLocaleCode = _supportedLanguages[index];
                    final bool isSelected = currentLanguageCode == targetLocaleCode;

                    return Localizations.override(
                      context: context,
                      locale: Locale(targetLocaleCode),
                      child: Builder(
                        builder: (forcedContext) {
                          return ListTile(
                            title: Text(
                              AppLocalizations.of(forcedContext)!.languageName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                            onTap: () async {
                              await changeLanguage(targetLocaleCode);

                              if (context.mounted) Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              }
            ),
          )
        ],
      ),
    );
  }
}