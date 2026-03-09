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

  /// Bottom navigation tab for skills and skill queue
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get tabSkills;

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

  /// Image pack check in progress
  ///
  /// In en, this message translates to:
  /// **'Checking for image pack...'**
  String get imageChecking;

  /// Image pack download in progress
  ///
  /// In en, this message translates to:
  /// **'Downloading image pack...'**
  String get imageDownloading;

  /// Image pack extraction in progress
  ///
  /// In en, this message translates to:
  /// **'Extracting image pack...'**
  String get imageExtracting;

  /// Image pack saving in progress
  ///
  /// In en, this message translates to:
  /// **'Saving image pack...'**
  String get imageSaving;

  /// First launch image download message
  ///
  /// In en, this message translates to:
  /// **'First launch: downloading image pack'**
  String get imageFirstLaunch;

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

  /// Captain section label
  ///
  /// In en, this message translates to:
  /// **'Captain'**
  String get captain;

  /// Implants section label
  ///
  /// In en, this message translates to:
  /// **'Implants'**
  String get implants;

  /// Boosters section label
  ///
  /// In en, this message translates to:
  /// **'Boosters'**
  String get boosters;

  /// Add implant button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addImplant;

  /// Add booster button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addBooster;

  /// Default character with all skills at level 0
  ///
  /// In en, this message translates to:
  /// **'All Skills Lv0'**
  String get allSkillsLevel0;

  /// Default character with all skills at level 5
  ///
  /// In en, this message translates to:
  /// **'All Skills Lv5'**
  String get allSkillsLevel5;

  /// Implant selection page title
  ///
  /// In en, this message translates to:
  /// **'Select Implant'**
  String get selectImplant;

  /// Booster selection page title
  ///
  /// In en, this message translates to:
  /// **'Select Booster'**
  String get selectBooster;

  /// Implant search hint
  ///
  /// In en, this message translates to:
  /// **'Search implant...'**
  String get searchImplant;

  /// Booster search hint
  ///
  /// In en, this message translates to:
  /// **'Search booster...'**
  String get searchBooster;

  /// Implant slot label
  ///
  /// In en, this message translates to:
  /// **'Slot {slot}'**
  String implantSlot(String slot);

  /// Empty implants placeholder
  ///
  /// In en, this message translates to:
  /// **'No implants'**
  String get noImplants;

  /// Empty boosters placeholder
  ///
  /// In en, this message translates to:
  /// **'No boosters'**
  String get noBoosters;

  /// Import implants from character
  ///
  /// In en, this message translates to:
  /// **'Import from Character'**
  String get importFromCharacter;

  /// Currently active implants
  ///
  /// In en, this message translates to:
  /// **'Active Implants'**
  String get activeImplants;

  /// Jump clone label
  ///
  /// In en, this message translates to:
  /// **'Jump Clone'**
  String get jumpClone;

  /// No active implants placeholder
  ///
  /// In en, this message translates to:
  /// **'No active implants'**
  String get noActiveImplants;

  /// Import implants page title
  ///
  /// In en, this message translates to:
  /// **'Import Implants'**
  String get importImplants;

  /// Implant import success message
  ///
  /// In en, this message translates to:
  /// **'Imported {count} implants'**
  String importImplantsSuccess(String count);

  /// Loading implants status
  ///
  /// In en, this message translates to:
  /// **'Loading implants...'**
  String get loadingImplants;

  /// Load implants error
  ///
  /// In en, this message translates to:
  /// **'Failed to load implants'**
  String get loadImplantsFailed;

  /// Clear all implants button
  ///
  /// In en, this message translates to:
  /// **'Clear All Implants'**
  String get clearAllImplants;

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

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginSsoTitle.
  ///
  /// In en, this message translates to:
  /// **'EVE SSO Login'**
  String get loginSsoTitle;

  /// No description provided for @loginSsoDescription.
  ///
  /// In en, this message translates to:
  /// **'Authenticate via EVE Online Single Sign-On'**
  String get loginSsoDescription;

  /// No description provided for @loginWithSso.
  ///
  /// In en, this message translates to:
  /// **'Login with SSO'**
  String get loginWithSso;

  /// No description provided for @loginOrToken.
  ///
  /// In en, this message translates to:
  /// **'Or enter Token'**
  String get loginOrToken;

  /// No description provided for @loginTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Paste JWT Token'**
  String get loginTokenHint;

  /// No description provided for @loginPasteToken.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get loginPasteToken;

  /// No description provided for @loginWithToken.
  ///
  /// In en, this message translates to:
  /// **'Login with Token'**
  String get loginWithToken;

  /// No description provided for @loginAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get loginAdvanced;

  /// No description provided for @serverUrlTitle.
  ///
  /// In en, this message translates to:
  /// **'Backend URL'**
  String get serverUrlTitle;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. http://127.0.0.1:8080/api/v1'**
  String get serverUrlHint;

  /// No description provided for @serverUrlSaved.
  ///
  /// In en, this message translates to:
  /// **'URL saved'**
  String get serverUrlSaved;

  /// No description provided for @serverUrlReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get serverUrlReset;

  /// No description provided for @serverUrlDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Backend URL'**
  String get serverUrlDialogTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @characterNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Please log in first'**
  String get characterNotLoggedIn;

  /// No description provided for @characterBind.
  ///
  /// In en, this message translates to:
  /// **'Bind Character'**
  String get characterBind;

  /// No description provided for @characterBindFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to bind character'**
  String get characterBindFailed;

  /// No description provided for @characterBindSuccess.
  ///
  /// In en, this message translates to:
  /// **'Character bound successfully'**
  String get characterBindSuccess;

  /// No description provided for @characterSetPrimary.
  ///
  /// In en, this message translates to:
  /// **'Set as Primary'**
  String get characterSetPrimary;

  /// No description provided for @characterSetPrimaryFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set primary character'**
  String get characterSetPrimaryFailed;

  /// No description provided for @characterUnbind.
  ///
  /// In en, this message translates to:
  /// **'Unbind'**
  String get characterUnbind;

  /// No description provided for @characterUnbindConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unbind character \"{name}\"?'**
  String characterUnbindConfirm(String name);

  /// No description provided for @characterUnbindFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unbind character'**
  String get characterUnbindFailed;

  /// No description provided for @characterNoCharacters.
  ///
  /// In en, this message translates to:
  /// **'No characters bound'**
  String get characterNoCharacters;

  /// No description provided for @characterPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get characterPrimary;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationTitle;

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationMarkAllRead;

  /// No description provided for @notificationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationEmpty;

  /// No description provided for @walletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get walletTitle;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get walletBalance;

  /// No description provided for @walletTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get walletTransactions;

  /// No description provided for @walletNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get walletNoTransactions;

  /// No description provided for @fleetTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleets'**
  String get fleetTitle;

  /// No description provided for @fleetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fleets'**
  String get fleetEmpty;

  /// No description provided for @fleetUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled Fleet'**
  String get fleetUntitled;

  /// No description provided for @fleetDetail.
  ///
  /// In en, this message translates to:
  /// **'Fleet Detail'**
  String get fleetDetail;

  /// No description provided for @fleetInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get fleetInfo;

  /// No description provided for @fleetMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get fleetMembers;

  /// No description provided for @fleetPap.
  ///
  /// In en, this message translates to:
  /// **'PAP'**
  String get fleetPap;

  /// No description provided for @fleetName.
  ///
  /// In en, this message translates to:
  /// **'Fleet Name'**
  String get fleetName;

  /// No description provided for @fleetStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get fleetStatus;

  /// No description provided for @fleetImportance.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get fleetImportance;

  /// No description provided for @fleetStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get fleetStartTime;

  /// No description provided for @fleetEndTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get fleetEndTime;

  /// No description provided for @fleetDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fleetDescription;

  /// No description provided for @fleetNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get fleetNoMembers;

  /// No description provided for @fleetNoPap.
  ///
  /// In en, this message translates to:
  /// **'No PAP records'**
  String get fleetNoPap;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get shopProducts;

  /// No description provided for @shopOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get shopOrders;

  /// No description provided for @shopRedeemCodes.
  ///
  /// In en, this message translates to:
  /// **'Redeem Codes'**
  String get shopRedeemCodes;

  /// No description provided for @shopEmpty.
  ///
  /// In en, this message translates to:
  /// **'No products'**
  String get shopEmpty;

  /// No description provided for @shopNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get shopNoOrders;

  /// No description provided for @shopNoRedeemCodes.
  ///
  /// In en, this message translates to:
  /// **'No redeem codes'**
  String get shopNoRedeemCodes;

  /// No description provided for @shopBuyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Purchase'**
  String get shopBuyConfirmTitle;

  /// No description provided for @shopBuyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Buy \"{name}\" for {price}?'**
  String shopBuyConfirm(String name, String price);

  /// No description provided for @shopBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get shopBuy;

  /// No description provided for @shopBuySuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase successful'**
  String get shopBuySuccess;

  /// No description provided for @shopBuyFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get shopBuyFailed;

  /// No description provided for @srpTitle.
  ///
  /// In en, this message translates to:
  /// **'SRP'**
  String get srpTitle;

  /// No description provided for @srpPrices.
  ///
  /// In en, this message translates to:
  /// **'Ship Prices'**
  String get srpPrices;

  /// No description provided for @srpMyApplications.
  ///
  /// In en, this message translates to:
  /// **'My Applications'**
  String get srpMyApplications;

  /// No description provided for @srpMyKillmails.
  ///
  /// In en, this message translates to:
  /// **'My Killmails'**
  String get srpMyKillmails;

  /// No description provided for @srpSearchShip.
  ///
  /// In en, this message translates to:
  /// **'Search ship...'**
  String get srpSearchShip;

  /// No description provided for @srpNoPrices.
  ///
  /// In en, this message translates to:
  /// **'No ship prices'**
  String get srpNoPrices;

  /// No description provided for @srpNoApplications.
  ///
  /// In en, this message translates to:
  /// **'No SRP applications'**
  String get srpNoApplications;

  /// No description provided for @srpNoKillmails.
  ///
  /// In en, this message translates to:
  /// **'No killmails'**
  String get srpNoKillmails;

  /// No description provided for @importImplantSet.
  ///
  /// In en, this message translates to:
  /// **'Import Set?'**
  String get importImplantSet;

  /// No description provided for @importImplantSetDesc.
  ///
  /// In en, this message translates to:
  /// **'Detected \"{series}\" set ({count} implants for slots 1-6). Import the full set?'**
  String importImplantSetDesc(String series, String count);

  /// No description provided for @importImplantSetJustOne.
  ///
  /// In en, this message translates to:
  /// **'Just This One'**
  String get importImplantSetJustOne;

  /// No description provided for @importImplantSetAll.
  ///
  /// In en, this message translates to:
  /// **'Import Full Set'**
  String get importImplantSetAll;

  /// Sidebar label for implants & clones
  ///
  /// In en, this message translates to:
  /// **'Implants'**
  String get tabImplants;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Jump clones section title
  ///
  /// In en, this message translates to:
  /// **'Jump Clones'**
  String get jumpClones;

  /// Shown when not logged in
  ///
  /// In en, this message translates to:
  /// **'Please log in first'**
  String get pleaseLogin;

  /// Character selector placeholder
  ///
  /// In en, this message translates to:
  /// **'Select Character'**
  String get selectCharacter;

  /// Generic loading label
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Home station section
  ///
  /// In en, this message translates to:
  /// **'Home Station'**
  String get homeStation;

  /// Active implants section
  ///
  /// In en, this message translates to:
  /// **'Current Active Implants'**
  String get currentActiveImplants;

  /// Jump fatigue cooldown label
  ///
  /// In en, this message translates to:
  /// **'Clone Jump Timer'**
  String get jumpFatigueCooldown;

  /// Clone is ready to jump
  ///
  /// In en, this message translates to:
  /// **'Clone Ready'**
  String get cloneReady;

  /// Last jump timestamp label
  ///
  /// In en, this message translates to:
  /// **'Last Jump'**
  String get lastJump;

  /// Last clone jump timestamp label
  ///
  /// In en, this message translates to:
  /// **'Last Clone Jump'**
  String get lastCloneJump;

  /// Sidebar label for NPC kills report
  ///
  /// In en, this message translates to:
  /// **'NPC Kills'**
  String get tabNpcKills;

  /// Dropdown option for all characters
  ///
  /// In en, this message translates to:
  /// **'All Characters'**
  String get npcKillsAllChars;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load NPC kills'**
  String get npcKillsLoadFailed;

  /// NPC bounty total
  ///
  /// In en, this message translates to:
  /// **'Bounty'**
  String get npcKillsBounty;

  /// ESS income total
  ///
  /// In en, this message translates to:
  /// **'ESS Income'**
  String get npcKillsEss;

  /// Tax total
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get npcKillsTax;

  /// Actual income total
  ///
  /// In en, this message translates to:
  /// **'Actual Income'**
  String get npcKillsActualIncome;

  /// Total record count
  ///
  /// In en, this message translates to:
  /// **'Total Records'**
  String get npcKillsTotalRecords;

  /// Estimated hours
  ///
  /// In en, this message translates to:
  /// **'Est. Hours'**
  String get npcKillsEstimatedHours;

  /// Section: by NPC
  ///
  /// In en, this message translates to:
  /// **'By NPC'**
  String get npcKillsByNpc;

  /// Section: by system
  ///
  /// In en, this message translates to:
  /// **'By System'**
  String get npcKillsBySystem;

  /// Empty state
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get npcKillsNoData;

  /// NPC name column
  ///
  /// In en, this message translates to:
  /// **'NPC Name'**
  String get npcKillsNpcName;

  /// Kill count column
  ///
  /// In en, this message translates to:
  /// **'Kills'**
  String get npcKillsCount;

  /// System name column
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get npcKillsSystemName;

  /// Amount column
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get npcKillsAmount;

  /// Journal section
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get npcKillsJournal;
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
