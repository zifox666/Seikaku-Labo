import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/shell_scaffold.dart';

/// 通知页面（占位）
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: MediaQuery.sizeOf(context).width < 720
            ? const DrawerMenuButton()
            : null,
        title: Text(l10n.notificationTitle),
      ),
      body: Center(
        child: Text(
          l10n.notificationEmpty,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          ),
        ),
      ),
    );
  }
}
