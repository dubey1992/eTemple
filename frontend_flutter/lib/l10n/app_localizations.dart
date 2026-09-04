import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('hi'),
  ];

  /// Temple name shown in the browser title bar and app bar
  ///
  /// In hi, this message translates to:
  /// **'राधा कृष्ण ठाकुरबाड़ी'**
  String get appTitle;

  /// Village and panchayat shown beneath the temple name
  ///
  /// In hi, this message translates to:
  /// **'अमरपुर पंखोरिया, कुर्मा पंचायत'**
  String get appSubtitle;

  /// Devotional invocation displayed above the temple name
  ///
  /// In hi, this message translates to:
  /// **'॥ राधे कृष्ण ॥'**
  String get invocation;

  /// No description provided for @languageLabel.
  ///
  /// In hi, this message translates to:
  /// **'भाषा'**
  String get languageLabel;

  /// No description provided for @languageHindi.
  ///
  /// In hi, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageEnglish.
  ///
  /// In hi, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @switchToEnglish.
  ///
  /// In hi, this message translates to:
  /// **'अंग्रेज़ी में देखें'**
  String get switchToEnglish;

  /// No description provided for @switchToHindi.
  ///
  /// In hi, this message translates to:
  /// **'हिन्दी में देखें'**
  String get switchToHindi;

  /// No description provided for @navHome.
  ///
  /// In hi, this message translates to:
  /// **'मुख पृष्ठ'**
  String get navHome;

  /// No description provided for @navAdmin.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंधन'**
  String get navAdmin;

  /// No description provided for @signIn.
  ///
  /// In hi, this message translates to:
  /// **'साइन इन'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In hi, this message translates to:
  /// **'साइन आउट'**
  String get signOut;

  /// Phase 0 placeholder heading; replaced by the CMS home page in Phase 1
  ///
  /// In hi, this message translates to:
  /// **'वेबसाइट तैयार की जा रही है'**
  String get foundationHeadline;

  /// No description provided for @foundationBody.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर की जानकारी, कार्यक्रम, चित्र और दान विवरण शीघ्र ही यहाँ उपलब्ध होंगे।'**
  String get foundationBody;

  /// No description provided for @foundationNote.
  ///
  /// In hi, this message translates to:
  /// **'यह पृष्ठ केवल तकनीकी आधार दर्शाता है। सामग्री अगले चरण में जोड़ी जाएगी।'**
  String get foundationNote;

  /// No description provided for @loginTitle.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंधन लॉगिन'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'केवल समिति सदस्यों के लिए'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In hi, this message translates to:
  /// **'ईमेल'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In hi, this message translates to:
  /// **'पासवर्ड'**
  String get passwordLabel;

  /// No description provided for @rememberMe.
  ///
  /// In hi, this message translates to:
  /// **'मुझे याद रखें'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In hi, this message translates to:
  /// **'पासवर्ड भूल गए?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In hi, this message translates to:
  /// **'पासवर्ड रीसेट करें'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'अपना पंजीकृत ईमेल दर्ज करें। यदि खाता सक्रिय है तो रीसेट लिंक भेजा जाएगा।'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In hi, this message translates to:
  /// **'रीसेट लिंक भेजें'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In hi, this message translates to:
  /// **'लॉगिन पर वापस जाएँ'**
  String get backToLogin;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंधन डैशबोर्ड'**
  String get adminDashboardTitle;

  /// No description provided for @adminWelcome.
  ///
  /// In hi, this message translates to:
  /// **'नमस्ते, {name}'**
  String adminWelcome(String name);

  /// No description provided for @adminFoundationNote.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंधन सुविधाएँ अगले चरणों में जोड़ी जाएँगी।'**
  String get adminFoundationNote;

  /// No description provided for @roleLabel.
  ///
  /// In hi, this message translates to:
  /// **'भूमिका'**
  String get roleLabel;

  /// No description provided for @validationRequired.
  ///
  /// In hi, this message translates to:
  /// **'यह जानकारी आवश्यक है'**
  String get validationRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In hi, this message translates to:
  /// **'कृपया वैध ईमेल पता दर्ज करें'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In hi, this message translates to:
  /// **'पासवर्ड कम से कम {count} अक्षरों का होना चाहिए'**
  String validationPasswordTooShort(int count);

  /// No description provided for @stateLoading.
  ///
  /// In hi, this message translates to:
  /// **'लोड हो रहा है…'**
  String get stateLoading;

  /// No description provided for @stateEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई जानकारी उपलब्ध नहीं है'**
  String get stateEmpty;

  /// No description provided for @stateRetry.
  ///
  /// In hi, this message translates to:
  /// **'पुनः प्रयास करें'**
  String get stateRetry;

  /// No description provided for @stateUnauthorizedTitle.
  ///
  /// In hi, this message translates to:
  /// **'अनुमति नहीं है'**
  String get stateUnauthorizedTitle;

  /// No description provided for @stateUnauthorizedBody.
  ///
  /// In hi, this message translates to:
  /// **'इस पृष्ठ को देखने के लिए आपके पास आवश्यक अनुमति नहीं है।'**
  String get stateUnauthorizedBody;

  /// No description provided for @notFoundTitle.
  ///
  /// In hi, this message translates to:
  /// **'पृष्ठ नहीं मिला'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In hi, this message translates to:
  /// **'आपके द्वारा खोजा गया पृष्ठ उपलब्ध नहीं है।'**
  String get notFoundBody;

  /// No description provided for @goHome.
  ///
  /// In hi, this message translates to:
  /// **'मुख पृष्ठ पर जाएँ'**
  String get goHome;

  /// No description provided for @errorNetwork.
  ///
  /// In hi, this message translates to:
  /// **'नेटवर्क उपलब्ध नहीं है। कृपया अपना इंटरनेट कनेक्शन जाँचें।'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In hi, this message translates to:
  /// **'सर्वर से उत्तर नहीं मिला। कृपया पुनः प्रयास करें।'**
  String get errorTimeout;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In hi, this message translates to:
  /// **'ईमेल या पासवर्ड गलत है।'**
  String get errorInvalidCredentials;

  /// No description provided for @errorAccountInactive.
  ///
  /// In hi, this message translates to:
  /// **'यह खाता सक्रिय नहीं है। कृपया समिति से संपर्क करें।'**
  String get errorAccountInactive;

  /// No description provided for @errorAccountBlocked.
  ///
  /// In hi, this message translates to:
  /// **'यह खाता अवरुद्ध कर दिया गया है। कृपया समिति से संपर्क करें।'**
  String get errorAccountBlocked;

  /// No description provided for @errorUnauthenticated.
  ///
  /// In hi, this message translates to:
  /// **'कृपया पुनः साइन इन करें।'**
  String get errorUnauthenticated;

  /// No description provided for @errorForbidden.
  ///
  /// In hi, this message translates to:
  /// **'यह कार्य करने की अनुमति नहीं है।'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In hi, this message translates to:
  /// **'अनुरोधित जानकारी नहीं मिली।'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In hi, this message translates to:
  /// **'दर्ज की गई जानकारी में त्रुटि है।'**
  String get errorValidation;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In hi, this message translates to:
  /// **'बहुत अधिक प्रयास। कृपया कुछ देर बाद पुनः प्रयास करें।'**
  String get errorTooManyRequests;

  /// No description provided for @errorSessionExpired.
  ///
  /// In hi, this message translates to:
  /// **'सत्र समाप्त हो गया है। कृपया पृष्ठ पुनः लोड करें।'**
  String get errorSessionExpired;

  /// No description provided for @errorServer.
  ///
  /// In hi, this message translates to:
  /// **'सर्वर में त्रुटि हुई। कृपया बाद में प्रयास करें।'**
  String get errorServer;

  /// No description provided for @errorUnknown.
  ///
  /// In hi, this message translates to:
  /// **'कुछ गलत हो गया। कृपया पुनः प्रयास करें।'**
  String get errorUnknown;

  /// No description provided for @navAbout.
  ///
  /// In hi, this message translates to:
  /// **'हमारे बारे में'**
  String get navAbout;

  /// No description provided for @navContact.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क'**
  String get navContact;

  /// No description provided for @heroDarshan.
  ///
  /// In hi, this message translates to:
  /// **'दर्शन करें'**
  String get heroDarshan;

  /// No description provided for @sectionAbout.
  ///
  /// In hi, this message translates to:
  /// **'हमारे बारे में'**
  String get sectionAbout;

  /// No description provided for @sectionAddress.
  ///
  /// In hi, this message translates to:
  /// **'पता एवं संपर्क'**
  String get sectionAddress;

  /// No description provided for @sectionReadMore.
  ///
  /// In hi, this message translates to:
  /// **'और पढ़ें'**
  String get sectionReadMore;

  /// No description provided for @contactPhone.
  ///
  /// In hi, this message translates to:
  /// **'दूरभाष'**
  String get contactPhone;

  /// No description provided for @contactEmail.
  ///
  /// In hi, this message translates to:
  /// **'ईमेल'**
  String get contactEmail;

  /// No description provided for @contactMap.
  ///
  /// In hi, this message translates to:
  /// **'मानचित्र पर देखें'**
  String get contactMap;

  /// No description provided for @fallbackNotice.
  ///
  /// In hi, this message translates to:
  /// **'यह सामग्री अभी केवल हिन्दी में उपलब्ध है।'**
  String get fallbackNotice;

  /// No description provided for @contentComingSoon.
  ///
  /// In hi, this message translates to:
  /// **'यह जानकारी शीघ्र ही जोड़ी जाएगी।'**
  String get contentComingSoon;

  /// No description provided for @addressComingSoon.
  ///
  /// In hi, this message translates to:
  /// **'पता शीघ्र ही जोड़ा जाएगा।'**
  String get addressComingSoon;

  /// No description provided for @adminContent.
  ///
  /// In hi, this message translates to:
  /// **'सामग्री प्रबंधन'**
  String get adminContent;

  /// No description provided for @adminPagesTitle.
  ///
  /// In hi, this message translates to:
  /// **'पृष्ठ'**
  String get adminPagesTitle;

  /// No description provided for @adminPagesSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'सार्वजनिक वेबसाइट की सामग्री यहाँ से संपादित करें।'**
  String get adminPagesSubtitle;

  /// No description provided for @adminEditPage.
  ///
  /// In hi, this message translates to:
  /// **'पृष्ठ संपादित करें'**
  String get adminEditPage;

  /// No description provided for @statusDraft.
  ///
  /// In hi, this message translates to:
  /// **'मसौदा'**
  String get statusDraft;

  /// No description provided for @statusPublished.
  ///
  /// In hi, this message translates to:
  /// **'प्रकाशित'**
  String get statusPublished;

  /// No description provided for @fieldTitleHindi.
  ///
  /// In hi, this message translates to:
  /// **'शीर्षक (हिन्दी)'**
  String get fieldTitleHindi;

  /// No description provided for @fieldTitleEnglish.
  ///
  /// In hi, this message translates to:
  /// **'शीर्षक (अंग्रेज़ी)'**
  String get fieldTitleEnglish;

  /// No description provided for @fieldContentHindi.
  ///
  /// In hi, this message translates to:
  /// **'सामग्री (हिन्दी)'**
  String get fieldContentHindi;

  /// No description provided for @fieldContentEnglish.
  ///
  /// In hi, this message translates to:
  /// **'सामग्री (अंग्रेज़ी)'**
  String get fieldContentEnglish;

  /// No description provided for @fieldMetaTitle.
  ///
  /// In hi, this message translates to:
  /// **'एसईओ शीर्षक'**
  String get fieldMetaTitle;

  /// No description provided for @fieldMetaDescription.
  ///
  /// In hi, this message translates to:
  /// **'एसईओ विवरण'**
  String get fieldMetaDescription;

  /// No description provided for @fieldOptional.
  ///
  /// In hi, this message translates to:
  /// **'वैकल्पिक'**
  String get fieldOptional;

  /// No description provided for @hindiRequiredHint.
  ///
  /// In hi, this message translates to:
  /// **'हिन्दी अनिवार्य है। अंग्रेज़ी न होने पर हिन्दी दिखाई जाएगी।'**
  String get hindiRequiredHint;

  /// No description provided for @actionSave.
  ///
  /// In hi, this message translates to:
  /// **'सहेजें'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In hi, this message translates to:
  /// **'रद्द करें'**
  String get actionCancel;

  /// No description provided for @actionPublish.
  ///
  /// In hi, this message translates to:
  /// **'प्रकाशित करें'**
  String get actionPublish;

  /// No description provided for @actionUnpublish.
  ///
  /// In hi, this message translates to:
  /// **'अप्रकाशित करें'**
  String get actionUnpublish;

  /// No description provided for @saveSuccess.
  ///
  /// In hi, this message translates to:
  /// **'परिवर्तन सहेज लिए गए।'**
  String get saveSuccess;

  /// No description provided for @englishMissingBadge.
  ///
  /// In hi, this message translates to:
  /// **'अंग्रेज़ी अनुपलब्ध'**
  String get englishMissingBadge;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
