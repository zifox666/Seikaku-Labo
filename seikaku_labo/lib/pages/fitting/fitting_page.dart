import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// 装配页面 - 主要功能入口
class FittingPage extends StatelessWidget {
  const FittingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fittingTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(120),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.fittingTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // TODO: 打开舰船选择页面
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.newFitting),
            ),
          ],
        ),
      ),
    );
  }
}
