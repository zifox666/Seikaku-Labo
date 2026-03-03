import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// 人物标签页 — 暂时留空
class CharacterTab extends StatelessWidget {
  const CharacterTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: theme.colorScheme.primary.withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.characterPlaceholder,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
