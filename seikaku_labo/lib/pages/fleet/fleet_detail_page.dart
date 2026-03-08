import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// 舰队详情页面（占位）
class FleetDetailPage extends StatelessWidget {
  final int fleetId;
  const FleetDetailPage({super.key, required this.fleetId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fleetDetail),
      ),
      body: Center(
        child: Text('Fleet #$fleetId'),
      ),
    );
  }
}
