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

  @override
  String get shipSelection => 'Select Ship';

  @override
  String get searchShip => 'Search ship...';

  @override
  String get fittingName => 'Fitting Name';

  @override
  String get createFitting => 'Create';

  @override
  String get cancel => 'Cancel';

  @override
  String get tabCharacterFit => 'Character';

  @override
  String get tabFittingDetail => 'Fitting';

  @override
  String get tabDrones => 'Drones';

  @override
  String get tabStats => 'Stats';

  @override
  String get emptySlot => 'Empty';

  @override
  String get noFittings => 'No fittings yet';

  @override
  String get noFittingsHint => 'Tap + to create a new fitting';

  @override
  String get deleteFitting => 'Delete Fitting';

  @override
  String deleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get capacitor => 'Capacitor';

  @override
  String get offense => 'Offense';

  @override
  String get defense => 'Defense';

  @override
  String get targeting => 'Targeting';

  @override
  String get navigation => 'Navigation';

  @override
  String get noDrones => 'No drones';

  @override
  String get addDrone => 'Add Drone';

  @override
  String get active => 'Active';

  @override
  String get passive => 'Passive';

  @override
  String get characterPlaceholder => 'Character management coming soon';

  @override
  String get statsPlaceholder => 'Stats will show after engine calculation';

  @override
  String get searchModule => 'Search module...';

  @override
  String get searchDrone => 'Search drone...';

  @override
  String get selectModule => 'Select Module';

  @override
  String get selectDrone => 'Select Drone';

  @override
  String get copy => 'Copy';

  @override
  String get ammo => 'Ammunition';

  @override
  String get removeCharge => 'Remove Charge';

  @override
  String get selectAmmo => 'Select Ammunition';

  @override
  String get resources => 'Resources';

  @override
  String get statCapacity => 'Capacity';

  @override
  String get statRechargeTime => 'Recharge Time';

  @override
  String get statCapStability => 'Cap Stability';

  @override
  String get statStable => 'Stable';

  @override
  String get statCapEmptyIn => 'Cap Empty In';

  @override
  String get statNoData => 'No data';

  @override
  String get statDpsNoReload => 'DPS (no reload)';

  @override
  String get statDpsReload => 'DPS (w/ reload)';

  @override
  String get statAlphaStrike => 'Alpha Strike';

  @override
  String get statDroneDps => 'Drone DPS';

  @override
  String get statEhp => 'EHP (uniform)';

  @override
  String get statShieldHp => 'Shield HP';

  @override
  String get statShieldRecharge => 'Shield Recharge';

  @override
  String get statPeakRecharge => 'Peak Passive Regen';

  @override
  String get statShieldResist => 'Shield Resist';

  @override
  String get statArmorHp => 'Armor HP';

  @override
  String get statArmorResist => 'Armor Resist';

  @override
  String get statHullHp => 'Hull HP';

  @override
  String get statHullResist => 'Hull Resist';

  @override
  String get statMaxTargetRange => 'Max Target Range';

  @override
  String get statMaxLockedTargets => 'Max Locked Targets';

  @override
  String get statScanResolution => 'Scan Resolution';

  @override
  String get statSensorStrength => 'Sensor Strength';

  @override
  String get statMaxVelocity => 'Max Velocity';

  @override
  String get statInertiaModifier => 'Inertia Modifier';

  @override
  String get statAlignTime => 'Align Time';

  @override
  String get statSignatureRadius => 'Signature Radius';

  @override
  String get statMass => 'Mass';

  @override
  String get statWarpSpeed => 'Warp Speed';

  @override
  String get statCpu => 'CPU';

  @override
  String statCpuUsedTotal(String used, String total) {
    return '$used / $total tf';
  }

  @override
  String get statPg => 'Power Grid';

  @override
  String statPgUsedTotal(String used, String total) {
    return '$used / $total MW';
  }

  @override
  String get statTurretHardpoints => 'Turret Hardpoints';

  @override
  String get statLauncherHardpoints => 'Launcher Hardpoints';

  @override
  String get statDroneBandwidth => 'Drone Bandwidth';

  @override
  String get statDroneCapacity => 'Drone Bay';

  @override
  String get statMaxActiveDrones => 'Max Active Drones';

  @override
  String get statCalibration => 'Calibration';

  @override
  String statUsedTotal(String used, String total) {
    return '$used / $total';
  }

  @override
  String get noModulesFound => 'No modules found';
}
