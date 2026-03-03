// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Seikaku Labo';

  @override
  String get tabFitting => 'Fitting';

  @override
  String get tabMarket => 'Market';

  @override
  String get tabCharacter => 'Character';

  @override
  String get tabSettings => 'Settings';

  @override
  String get fittingTitle => 'Ship Fitting';

  @override
  String get marketTitle => 'Market Browser';

  @override
  String get characterTitle => 'Character';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get newFitting => 'New Fitting';

  @override
  String get selectShip => 'Select Ship';

  @override
  String get highSlots => 'High Slots';

  @override
  String get mediumSlots => 'Medium Slots';

  @override
  String get lowSlots => 'Low Slots';

  @override
  String get rigSlots => 'Rig Slots';

  @override
  String get drones => 'Drones';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get sdeDatabase => 'SDE Database';

  @override
  String get sdeDatabaseNotLoaded => 'Not loaded';

  @override
  String get sdeDatabaseLoaded => 'Loaded';

  @override
  String get sdeChecking => 'Checking for SDE updates...';

  @override
  String get sdeDownloading => 'Downloading SDE database...';

  @override
  String get sdeExtracting => 'Extracting database...';

  @override
  String get sdeSaving => 'Saving database...';

  @override
  String get sdeReady => 'Database ready';

  @override
  String sdeUpdateAvailable(String tag) {
    return 'Update available: $tag';
  }

  @override
  String sdeCurrentVersion(String tag) {
    return 'Current: $tag';
  }

  @override
  String get sdeDownloadUpdate => 'Download Update';

  @override
  String get sdeCheckUpdate => 'Check for Update';

  @override
  String get sdeDownloadFailed => 'Download failed';

  @override
  String get sdeRetry => 'Retry';

  @override
  String get sdeNoNetwork =>
      'Cannot connect to server. Please check your network.';

  @override
  String get sdeFirstLaunch => 'First launch: downloading EVE SDE database';

  @override
  String sdeSize(String size) {
    return 'Size: $size';
  }
}
