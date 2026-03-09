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
  String get tabSkills => 'Skills';

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
  String get imageChecking => 'Checking for image pack...';

  @override
  String get imageDownloading => 'Downloading image pack...';

  @override
  String get imageExtracting => 'Extracting image pack...';

  @override
  String get imageSaving => 'Saving image pack...';

  @override
  String get imageFirstLaunch => 'First launch: downloading image pack';

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
  String get renameFitting => 'Rename Fitting';

  @override
  String get rename => 'Rename';

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
  String get captain => 'Captain';

  @override
  String get implants => 'Implants';

  @override
  String get boosters => 'Boosters';

  @override
  String get addImplant => 'Add';

  @override
  String get addBooster => 'Add';

  @override
  String get allSkillsLevel0 => 'All Skills Lv0';

  @override
  String get allSkillsLevel5 => 'All Skills Lv5';

  @override
  String get selectImplant => 'Select Implant';

  @override
  String get selectBooster => 'Select Booster';

  @override
  String get searchImplant => 'Search implant...';

  @override
  String get searchBooster => 'Search booster...';

  @override
  String implantSlot(String slot) {
    return 'Slot $slot';
  }

  @override
  String get noImplants => 'No implants';

  @override
  String get noBoosters => 'No boosters';

  @override
  String get importFromCharacter => 'Import from Character';

  @override
  String get activeImplants => 'Active Implants';

  @override
  String get jumpClone => 'Jump Clone';

  @override
  String get noActiveImplants => 'No active implants';

  @override
  String get importImplants => 'Import Implants';

  @override
  String importImplantsSuccess(String count) {
    return 'Imported $count implants';
  }

  @override
  String get loadingImplants => 'Loading implants...';

  @override
  String get loadImplantsFailed => 'Failed to load implants';

  @override
  String get clearAllImplants => 'Clear All Implants';

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

  @override
  String get loginTitle => 'Login';

  @override
  String get loginSsoTitle => 'EVE SSO Login';

  @override
  String get loginSsoDescription =>
      'Authenticate via EVE Online Single Sign-On';

  @override
  String get loginWithSso => 'Login with SSO';

  @override
  String get loginOrToken => 'Or enter Token';

  @override
  String get loginTokenHint => 'Paste JWT Token';

  @override
  String get loginPasteToken => 'Paste';

  @override
  String get loginWithToken => 'Login with Token';

  @override
  String get loginAdvanced => 'Advanced Options';

  @override
  String get serverUrlTitle => 'Backend URL';

  @override
  String get serverUrlHint => 'e.g. http://127.0.0.1:8080/api/v1';

  @override
  String get serverUrlSaved => 'URL saved';

  @override
  String get serverUrlReset => 'Reset to default';

  @override
  String get serverUrlDialogTitle => 'Set Backend URL';

  @override
  String get ok => 'OK';

  @override
  String get characterNotLoggedIn => 'Please log in first';

  @override
  String get characterBind => 'Bind Character';

  @override
  String get characterBindFailed => 'Failed to bind character';

  @override
  String get characterBindSuccess => 'Character bound successfully';

  @override
  String get characterSetPrimary => 'Set as Primary';

  @override
  String get characterSetPrimaryFailed => 'Failed to set primary character';

  @override
  String get characterUnbind => 'Unbind';

  @override
  String characterUnbindConfirm(String name) {
    return 'Unbind character \"$name\"?';
  }

  @override
  String get characterUnbindFailed => 'Failed to unbind character';

  @override
  String get characterNoCharacters => 'No characters bound';

  @override
  String get characterPrimary => 'Primary';

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get notificationMarkAllRead => 'Mark all read';

  @override
  String get notificationEmpty => 'No notifications';

  @override
  String get walletTitle => 'Wallet';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletTransactions => 'Transactions';

  @override
  String get walletNoTransactions => 'No transactions';

  @override
  String get fleetTitle => 'Fleets';

  @override
  String get fleetEmpty => 'No fleets';

  @override
  String get fleetUntitled => 'Untitled Fleet';

  @override
  String get fleetDetail => 'Fleet Detail';

  @override
  String get fleetInfo => 'Info';

  @override
  String get fleetMembers => 'Members';

  @override
  String get fleetPap => 'PAP';

  @override
  String get fleetName => 'Fleet Name';

  @override
  String get fleetStatus => 'Status';

  @override
  String get fleetImportance => 'Importance';

  @override
  String get fleetStartTime => 'Start Time';

  @override
  String get fleetEndTime => 'End Time';

  @override
  String get fleetDescription => 'Description';

  @override
  String get fleetNoMembers => 'No members';

  @override
  String get fleetNoPap => 'No PAP records';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopProducts => 'Products';

  @override
  String get shopOrders => 'My Orders';

  @override
  String get shopRedeemCodes => 'Redeem Codes';

  @override
  String get shopEmpty => 'No products';

  @override
  String get shopNoOrders => 'No orders';

  @override
  String get shopNoRedeemCodes => 'No redeem codes';

  @override
  String get shopBuyConfirmTitle => 'Confirm Purchase';

  @override
  String shopBuyConfirm(String name, String price) {
    return 'Buy \"$name\" for $price?';
  }

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopBuySuccess => 'Purchase successful';

  @override
  String get shopBuyFailed => 'Purchase failed';

  @override
  String get srpTitle => 'SRP';

  @override
  String get srpPrices => 'Ship Prices';

  @override
  String get srpMyApplications => 'My Applications';

  @override
  String get srpMyKillmails => 'My Killmails';

  @override
  String get srpSearchShip => 'Search ship...';

  @override
  String get srpNoPrices => 'No ship prices';

  @override
  String get srpNoApplications => 'No SRP applications';

  @override
  String get srpNoKillmails => 'No killmails';

  @override
  String get importImplantSet => 'Import Set?';

  @override
  String importImplantSetDesc(String series, String count) {
    return 'Detected \"$series\" set ($count implants for slots 1-6). Import the full set?';
  }

  @override
  String get importImplantSetJustOne => 'Just This One';

  @override
  String get importImplantSetAll => 'Import Full Set';

  @override
  String get tabImplants => 'Implants';

  @override
  String get refresh => 'Refresh';

  @override
  String get jumpClones => 'Jump Clones';

  @override
  String get pleaseLogin => 'Please log in first';

  @override
  String get selectCharacter => 'Select Character';

  @override
  String get loading => 'Loading...';

  @override
  String get homeStation => 'Home Station';

  @override
  String get currentActiveImplants => 'Current Active Implants';

  @override
  String get jumpFatigueCooldown => 'Clone Jump Timer';

  @override
  String get cloneReady => 'Clone Ready';

  @override
  String get lastJump => 'Last Jump';

  @override
  String get lastCloneJump => 'Last Clone Jump';

  @override
  String get tabNpcKills => 'NPC Kills';

  @override
  String get npcKillsAllChars => 'All Characters';

  @override
  String get npcKillsLoadFailed => 'Failed to load NPC kills';

  @override
  String get npcKillsBounty => 'Bounty';

  @override
  String get npcKillsEss => 'ESS Income';

  @override
  String get npcKillsTax => 'Tax';

  @override
  String get npcKillsActualIncome => 'Actual Income';

  @override
  String get npcKillsTotalRecords => 'Total Records';

  @override
  String get npcKillsEstimatedHours => 'Est. Hours';

  @override
  String get npcKillsByNpc => 'By NPC';

  @override
  String get npcKillsBySystem => 'By System';

  @override
  String get npcKillsNoData => 'No data';

  @override
  String get npcKillsNpcName => 'NPC Name';

  @override
  String get npcKillsCount => 'Kills';

  @override
  String get npcKillsSystemName => 'System';

  @override
  String get npcKillsAmount => 'Amount';

  @override
  String get npcKillsJournal => 'Journal';

  @override
  String get cloudSaveTitle => 'Save to Game';

  @override
  String get cloudSavePrompt => 'Fitting has been modified. Save to game?';

  @override
  String get cloudSaveConfirm => 'Save';

  @override
  String get cloudSaveSkip => 'Don\'t Save';

  @override
  String get cloudSaveSuccess => 'Saved to game';

  @override
  String get cloudSaveFailed => 'Save failed';

  @override
  String get cloudSaveNoCharacter => 'Please set a primary character first';

  @override
  String get cloudSynced => 'Synced to game';

  @override
  String get cloudModified => 'Locally modified';

  @override
  String get cloudNotSynced => 'Local only';

  @override
  String get cloudFetch => 'Fetch fittings from game';

  @override
  String get cloudFetchFailed => 'Failed to fetch fittings';

  @override
  String get cloudFittings => 'Game Fittings';

  @override
  String get cloudNoFittings => 'No fittings in game';

  @override
  String get cloudSearchHint => 'Search fittings...';

  @override
  String get cloudNoResults => 'No matching fittings';

  @override
  String get cloudImport => 'Import';

  @override
  String cloudImportSuccess(String name) {
    return 'Imported \"$name\"';
  }
}
