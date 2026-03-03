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
