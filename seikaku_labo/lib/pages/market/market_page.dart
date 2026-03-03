import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// 市场浏览页面 - 占位
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withAlpha(120),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.comingSoon,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
