import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Seikaku Labo'**
  String get appTitle;

  /// Bottom navigation tab for ship fitting
  ///
  /// In en, this message translates to:
  /// **'Fitting'**
  String get tabFitting;

  /// Bottom navigation tab for market browser
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get tabMarket;

  /// Bottom navigation tab for character info
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get tabCharacter;

  /// Bottom navigation tab for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// Title for fitting page
  ///
  /// In en, this message translates to:
  /// **'Ship Fitting'**
  String get fittingTitle;

  /// Title for market page
  ///
  /// In en, this message translates to:
  /// **'Market Browser'**
  String get marketTitle;

  /// Title for character page
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get characterTitle;

  /// Title for settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Button to create a new fitting
  ///
  /// In en, this message translates to:
  /// **'New Fitting'**
  String get newFitting;

  /// Prompt to select a ship
  ///
  /// In en, this message translates to:
  /// **'Select Ship'**
  String get selectShip;

  /// High power slots
  ///
  /// In en, this message translates to:
  /// **'High Slots'**
  String get highSlots;

  /// Medium power slots
  ///
  /// In en, this message translates to:
  /// **'Medium Slots'**
  String get mediumSlots;

  /// Low power slots
  ///
  /// In en, this message translates to:
  /// **'Low Slots'**
  String get lowSlots;

  /// Rig slots
  ///
  /// In en, this message translates to:
  /// **'Rig Slots'**
  String get rigSlots;

  /// Drones section
  ///
  /// In en, this message translates to:
  /// **'Drones'**
  String get drones;

  /// Placeholder text for unfinished features
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// SDE database setting
  ///
  /// In en, this message translates to:
  /// **'SDE Database'**
  String get sdeDatabase;

  /// SDE database not loaded status
  ///
  /// In en, this message translates to:
  /// **'Not loaded'**
  String get sdeDatabaseNotLoaded;

  /// SDE database loaded status
  ///
  /// In en, this message translates to:
  /// **'Loaded'**
  String get sdeDatabaseLoaded;

  /// SDE update check in progress
  ///
  /// In en, this message translates to:
  /// **'Checking for SDE updates...'**
  String get sdeChecking;

  /// SDE download in progress
  ///
  /// In en, this message translates to:
  /// **'Downloading SDE database...'**
  String get sdeDownloading;

  /// SDE extraction in progress
  ///
  /// In en, this message translates to:
  /// **'Extracting database...'**
  String get sdeExtracting;

  /// SDE saving in progress
  ///
  /// In en, this message translates to:
  /// **'Saving database...'**
  String get sdeSaving;

  /// SDE database is ready
  ///
  /// In en, this message translates to:
  /// **'Database ready'**
  String get sdeReady;

  /// SDE update available message
  ///
  /// In en, this message translates to:
  /// **'Update available: {tag}'**
  String sdeUpdateAvailable(String tag);

  /// Current SDE version
  ///
  /// In en, this message translates to:
  /// **'Current: {tag}'**
  String sdeCurrentVersion(String tag);

  /// Download SDE update button
  ///
  /// In en, this message translates to:
  /// **'Download Update'**
  String get sdeDownloadUpdate;

  /// Check for SDE update button
  ///
  /// In en, this message translates to:
  /// **'Check for Update'**
  String get sdeCheckUpdate;

  /// SDE download failed
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get sdeDownloadFailed;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get sdeRetry;

  /// No network connection message
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Please check your network.'**
  String get sdeNoNetwork;

  /// First launch download message
  ///
  /// In en, this message translates to:
  /// **'First launch: downloading EVE SDE database'**
  String get sdeFirstLaunch;

  /// File size display
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String sdeSize(String size);

  /// Ship selection page title
  ///
  /// In en, this message translates to:
  /// **'Select Ship'**
  String get shipSelection;

  /// Ship search hint
  ///
  /// In en, this message translates to:
  /// **'Search ship...'**
  String get searchShip;

  /// Label for fitting name input
  ///
  /// In en, this message translates to:
  /// **'Fitting Name'**
  String get fittingName;

  /// Create fitting button
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createFitting;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Character tab in fitting detail
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get tabCharacterFit;

  /// Fitting tab in fitting detail
  ///
  /// In en, this message translates to:
  /// **'Fitting'**
  String get tabFittingDetail;

  /// Drones tab in fitting detail
  ///
  /// In en, this message translates to:
  /// **'Drones'**
  String get tabDrones;

  /// Statistics tab in fitting detail
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// Empty slot placeholder
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get emptySlot;

  /// Empty state text when no fittings exist
  ///
  /// In en, this message translates to:
  /// **'No fittings yet'**
  String get noFittings;

  /// Hint text for creating first fitting
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a new fitting'**
  String get noFittingsHint;

  /// Delete fitting button
  ///
  /// In en, this message translates to:
  /// **'Delete Fitting'**
  String get deleteFitting;

  /// Delete confirmation message
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteConfirm(String name);

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Capacitor stats label
  ///
  /// In en, this message translates to:
  /// **'Capacitor'**
  String get capacitor;

  /// Offense stats label
  ///
  /// In en, this message translates to:
  /// **'Offense'**
  String get offense;

  /// Defense stats label
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get defense;

  /// Targeting stats label
  ///
  /// In en, this message translates to:
  /// **'Targeting'**
  String get targeting;

  /// Navigation stats label
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// Empty drones placeholder
  ///
  /// In en, this message translates to:
  /// **'No drones'**
  String get noDrones;

  /// Add drone button
  ///
  /// In en, this message translates to:
  /// **'Add Drone'**
  String get addDrone;

  /// Active state label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Passive state label
  ///
  /// In en, this message translates to:
  /// **'Passive'**
  String get passive;

  /// Character tab placeholder
  ///
  /// In en, this message translates to:
  /// **'Character management coming soon'**
  String get characterPlaceholder;

  /// Stats tab placeholder
  ///
  /// In en, this message translates to:
  /// **'Stats will show after engine calculation'**
  String get statsPlaceholder;

  /// Module search hint
  ///
  /// In en, this message translates to:
  /// **'Search module...'**
  String get searchModule;

  /// Drone search hint
  ///
  /// In en, this message translates to:
  /// **'Search drone...'**
  String get searchDrone;

  /// Module selection page title
  ///
  /// In en, this message translates to:
  /// **'Select Module'**
  String get selectModule;

  /// Drone selection page title
  ///
  /// In en, this message translates to:
  /// **'Select Drone'**
  String get selectDrone;

  /// Copy module menu item
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Ammunition menu item
  ///
  /// In en, this message translates to:
  /// **'Ammunition'**
  String get ammo;

  /// Remove charge menu item
  ///
  /// In en, this message translates to:
  /// **'Remove Charge'**
  String get removeCharge;

  /// Ammunition selection page title
  ///
  /// In en, this message translates to:
  /// **'Select Ammunition'**
  String get selectAmmo;

  /// Fitting resources stats category
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @statCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get statCapacity;

  /// No description provided for @statRechargeTime.
  ///
  /// In en, this message translates to:
  /// **'Recharge Time'**
  String get statRechargeTime;

  /// No description provided for @statCapStability.
  ///
  /// In en, this message translates to:
  /// **'Cap Stability'**
  String get statCapStability;

  /// No description provided for @statStable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get statStable;

  /// No description provided for @statCapEmptyIn.
  ///
  /// In en, this message translates to:
  /// **'Cap Empty In'**
  String get statCapEmptyIn;

  /// No description provided for @statNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get statNoData;

  /// No description provided for @statDpsNoReload.
  ///
  /// In en, this message translates to:
  /// **'DPS (no reload)'**
  String get statDpsNoReload;

  /// No description provided for @statDpsReload.
  ///
  /// In en, this message translates to:
  /// **'DPS (w/ reload)'**
  String get statDpsReload;

  /// No description provided for @statAlphaStrike.
  ///
  /// In en, this message translates to:
  /// **'Alpha Strike'**
  String get statAlphaStrike;

  /// No description provided for @statDroneDps.
  ///
  /// In en, this message translates to:
  /// **'Drone DPS'**
  String get statDroneDps;

  /// No description provided for @statEhp.
  ///
  /// In en, this message translates to:
  /// **'EHP (uniform)'**
  String get statEhp;

  /// No description provided for @statShieldHp.
  ///
  /// In en, this message translates to:
  /// **'Shield HP'**
  String get statShieldHp;

  /// No description provided for @statShieldRecharge.
  ///
  /// In en, this message translates to:
  /// **'Shield Recharge'**
  String get statShieldRecharge;

  /// No description provided for @statPeakRecharge.
  ///
  /// In en, this message translates to:
  /// **'Peak Passive Regen'**
  String get statPeakRecharge;

  /// No description provided for @statShieldResist.
  ///
  /// In en, this message translates to:
  /// **'Shield Resist'**
  String get statShieldResist;

  /// No description provided for @statArmorHp.
  ///
  /// In en, this message translates to:
  /// **'Armor HP'**
  String get statArmorHp;

  /// No description provided for @statArmorResist.
  ///
  /// In en, this message translates to:
  /// **'Armor Resist'**
  String get statArmorResist;

  /// No description provided for @statHullHp.
  ///
  /// In en, this message translates to:
  /// **'Hull HP'**
  String get statHullHp;

  /// No description provided for @statHullResist.
  ///
  /// In en, this message translates to:
  /// **'Hull Resist'**
  String get statHullResist;

  /// No description provided for @statMaxTargetRange.
  ///
  /// In en, this message translates to:
  /// **'Max Target Range'**
  String get statMaxTargetRange;

  /// No description provided for @statMaxLockedTargets.
  ///
  /// In en, this message translates to:
  /// **'Max Locked Targets'**
  String get statMaxLockedTargets;

  /// No description provided for @statScanResolution.
  ///
  /// In en, this message translates to:
  /// **'Scan Resolution'**
  String get statScanResolution;

  /// No description provided for @statSensorStrength.
  ///
  /// In en, this message translates to:
  /// **'Sensor Strength'**
  String get statSensorStrength;

  /// No description provided for @statMaxVelocity.
  ///
  /// In en, this message translates to:
  /// **'Max Velocity'**
  String get statMaxVelocity;

  /// No description provided for @statInertiaModifier.
  ///
  /// In en, this message translates to:
  /// **'Inertia Modifier'**
  String get statInertiaModifier;

  /// No description provided for @statAlignTime.
  ///
  /// In en, this message translates to:
  /// **'Align Time'**
  String get statAlignTime;

  /// No description provided for @statSignatureRadius.
  ///
  /// In en, this message translates to:
  /// **'Signature Radius'**
  String get statSignatureRadius;

  /// No description provided for @statMass.
  ///
  /// In en, this message translates to:
  /// **'Mass'**
  String get statMass;

  /// No description provided for @statWarpSpeed.
  ///
  /// In en, this message translates to:
  /// **'Warp Speed'**
  String get statWarpSpeed;

  /// No description provided for @statCpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get statCpu;

  /// No description provided for @statCpuUsedTotal.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} tf'**
  String statCpuUsedTotal(String used, String total);

  /// No description provided for @statPg.
  ///
  /// In en, this message translates to:
  /// **'Power Grid'**
  String get statPg;

  /// No description provided for @statPgUsedTotal.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} MW'**
  String statPgUsedTotal(String used, String total);

  /// No description provided for @statTurretHardpoints.
  ///
  /// In en, this message translates to:
  /// **'Turret Hardpoints'**
  String get statTurretHardpoints;

  /// No description provided for @statLauncherHardpoints.
  ///
  /// In en, this message translates to:
  /// **'Launcher Hardpoints'**
  String get statLauncherHardpoints;

  /// No description provided for @statDroneBandwidth.
  ///
  /// In en, this message translates to:
  /// **'Drone Bandwidth'**
  String get statDroneBandwidth;

  /// No description provided for @statDroneCapacity.
  ///
  /// In en, this message translates to:
  /// **'Drone Bay'**
  String get statDroneCapacity;

  /// No description provided for @statMaxActiveDrones.
  ///
  /// In en, this message translates to:
  /// **'Max Active Drones'**
  String get statMaxActiveDrones;

  /// No description provided for @statCalibration.
  ///
  /// In en, this message translates to:
  /// **'Calibration'**
  String get statCalibration;

  /// No description provided for @statUsedTotal.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total}'**
  String statUsedTotal(String used, String total);

  /// No description provided for @noModulesFound.
  ///
  /// In en, this message translates to:
  /// **'No modules found'**
  String get noModulesFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
