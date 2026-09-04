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

  /// Application shell fallback for the temple name. Since Phase 3 the real name comes from temple_profile; this is shown only while that request is in flight or has failed.
  ///
  /// In hi, this message translates to:
  /// **'राधा कृष्ण ठाकुरबाड़ी'**
  String get appTitle;

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

  /// No description provided for @dashboardWelcome.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंधन डैशबोर्ड'**
  String get dashboardWelcome;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'अपनी अनुमति के अनुसार उपलब्ध विकल्प नीचे दिए गए हैं।'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardNoAccess.
  ///
  /// In hi, this message translates to:
  /// **'आपके खाते को अभी किसी प्रबंधन सुविधा की अनुमति नहीं है।'**
  String get dashboardNoAccess;

  /// No description provided for @navUsers.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य खाते'**
  String get navUsers;

  /// No description provided for @navUsersDesc.
  ///
  /// In hi, this message translates to:
  /// **'समिति सदस्यों के खाते बनाएँ और प्रबंधित करें'**
  String get navUsersDesc;

  /// No description provided for @navRoles.
  ///
  /// In hi, this message translates to:
  /// **'भूमिका एवं अनुमति'**
  String get navRoles;

  /// No description provided for @navRolesDesc.
  ///
  /// In hi, this message translates to:
  /// **'प्रत्येक भूमिका क्या कर सकती है, यह निर्धारित करें'**
  String get navRolesDesc;

  /// No description provided for @navPagesDesc.
  ///
  /// In hi, this message translates to:
  /// **'सार्वजनिक वेबसाइट की सामग्री संपादित करें'**
  String get navPagesDesc;

  /// No description provided for @navSiteSettings.
  ///
  /// In hi, this message translates to:
  /// **'साइट सेटिंग्स'**
  String get navSiteSettings;

  /// No description provided for @navSiteSettingsDesc.
  ///
  /// In hi, this message translates to:
  /// **'टैगलाइन, पता, मेन्यू और फुटर'**
  String get navSiteSettingsDesc;

  /// No description provided for @usersTitle.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य खाते'**
  String get usersTitle;

  /// No description provided for @usersSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'समिति सदस्यों के खाते यहाँ से प्रबंधित करें।'**
  String get usersSubtitle;

  /// No description provided for @userNew.
  ///
  /// In hi, this message translates to:
  /// **'नया खाता'**
  String get userNew;

  /// No description provided for @userEdit.
  ///
  /// In hi, this message translates to:
  /// **'खाता संपादित करें'**
  String get userEdit;

  /// No description provided for @userCreate.
  ///
  /// In hi, this message translates to:
  /// **'खाता बनाएँ'**
  String get userCreate;

  /// No description provided for @userNeverSignedIn.
  ///
  /// In hi, this message translates to:
  /// **'कभी साइन इन नहीं किया'**
  String get userNeverSignedIn;

  /// No description provided for @userLastLogin.
  ///
  /// In hi, this message translates to:
  /// **'अंतिम लॉगिन'**
  String get userLastLogin;

  /// No description provided for @fieldFirstName.
  ///
  /// In hi, this message translates to:
  /// **'नाम'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In hi, this message translates to:
  /// **'उपनाम'**
  String get fieldLastName;

  /// No description provided for @fieldMobile.
  ///
  /// In hi, this message translates to:
  /// **'मोबाइल'**
  String get fieldMobile;

  /// No description provided for @fieldRole.
  ///
  /// In hi, this message translates to:
  /// **'भूमिका'**
  String get fieldRole;

  /// No description provided for @fieldStatus.
  ///
  /// In hi, this message translates to:
  /// **'स्थिति'**
  String get fieldStatus;

  /// No description provided for @statusActive.
  ///
  /// In hi, this message translates to:
  /// **'सक्रिय'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In hi, this message translates to:
  /// **'निष्क्रिय'**
  String get statusInactive;

  /// No description provided for @statusBlocked.
  ///
  /// In hi, this message translates to:
  /// **'अवरुद्ध'**
  String get statusBlocked;

  /// No description provided for @userPasswordHint.
  ///
  /// In hi, this message translates to:
  /// **'नया सदस्य ईमेल पर भेजे गए लिंक से अपना पासवर्ड स्वयं बनाएगा।'**
  String get userPasswordHint;

  /// No description provided for @userSendReset.
  ///
  /// In hi, this message translates to:
  /// **'पासवर्ड लिंक भेजें'**
  String get userSendReset;

  /// No description provided for @userResetSent.
  ///
  /// In hi, this message translates to:
  /// **'पासवर्ड लिंक भेज दिया गया।'**
  String get userResetSent;

  /// No description provided for @userCreated.
  ///
  /// In hi, this message translates to:
  /// **'खाता बना दिया गया और पासवर्ड लिंक भेज दिया गया।'**
  String get userCreated;

  /// No description provided for @rolesTitle.
  ///
  /// In hi, this message translates to:
  /// **'भूमिका एवं अनुमति'**
  String get rolesTitle;

  /// No description provided for @rolesSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'प्रत्येक भूमिका किन मॉड्यूल तक पहुँच सकती है।'**
  String get rolesSubtitle;

  /// No description provided for @roleMembers.
  ///
  /// In hi, this message translates to:
  /// **'{count} खाते'**
  String roleMembers(int count);

  /// No description provided for @rolePermissionCount.
  ///
  /// In hi, this message translates to:
  /// **'{count} अनुमतियाँ'**
  String rolePermissionCount(int count);

  /// No description provided for @roleFixed.
  ///
  /// In hi, this message translates to:
  /// **'सुपर एडमिन को सदैव सभी अनुमतियाँ रहती हैं।'**
  String get roleFixed;

  /// No description provided for @rolePermissionsTitle.
  ///
  /// In hi, this message translates to:
  /// **'अनुमतियाँ'**
  String get rolePermissionsTitle;

  /// No description provided for @permissionsSaved.
  ///
  /// In hi, this message translates to:
  /// **'अनुमतियाँ सहेज ली गईं।'**
  String get permissionsSaved;

  /// No description provided for @modulePhasePending.
  ///
  /// In hi, this message translates to:
  /// **'चरण {phase} में उपलब्ध होगा'**
  String modulePhasePending(int phase);

  /// No description provided for @loginHistoryTitle.
  ///
  /// In hi, this message translates to:
  /// **'लॉगिन इतिहास'**
  String get loginHistoryTitle;

  /// No description provided for @loginHistoryEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई लॉगिन दर्ज नहीं है।'**
  String get loginHistoryEmpty;

  /// No description provided for @loginSuccess.
  ///
  /// In hi, this message translates to:
  /// **'सफल'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In hi, this message translates to:
  /// **'असफल'**
  String get loginFailed;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In hi, this message translates to:
  /// **'नया पासवर्ड बनाएँ'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'अपने खाते के लिए नया पासवर्ड दर्ज करें।'**
  String get resetPasswordSubtitle;

  /// No description provided for @fieldNewPassword.
  ///
  /// In hi, this message translates to:
  /// **'नया पासवर्ड'**
  String get fieldNewPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In hi, this message translates to:
  /// **'पासवर्ड दोबारा दर्ज करें'**
  String get fieldConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In hi, this message translates to:
  /// **'दोनों पासवर्ड एक जैसे नहीं हैं'**
  String get passwordsDoNotMatch;

  /// No description provided for @resetPasswordDone.
  ///
  /// In hi, this message translates to:
  /// **'पासवर्ड बदल दिया गया। अब साइन इन करें।'**
  String get resetPasswordDone;

  /// No description provided for @resetLinkInvalid.
  ///
  /// In hi, this message translates to:
  /// **'यह लिंक अमान्य है या समाप्त हो चुका है।'**
  String get resetLinkInvalid;

  /// No description provided for @siteSettingsTitle.
  ///
  /// In hi, this message translates to:
  /// **'साइट सेटिंग्स'**
  String get siteSettingsTitle;

  /// No description provided for @siteSettingsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मुख पृष्ठ की पंक्ति, पता और फुटर।'**
  String get siteSettingsSubtitle;

  /// No description provided for @fieldTagline.
  ///
  /// In hi, this message translates to:
  /// **'टैगलाइन'**
  String get fieldTagline;

  /// No description provided for @fieldFooter.
  ///
  /// In hi, this message translates to:
  /// **'फुटर पंक्ति'**
  String get fieldFooter;

  /// No description provided for @fieldVillage.
  ///
  /// In hi, this message translates to:
  /// **'गाँव'**
  String get fieldVillage;

  /// No description provided for @fieldPanchayat.
  ///
  /// In hi, this message translates to:
  /// **'पंचायत'**
  String get fieldPanchayat;

  /// No description provided for @fieldPoliceStation.
  ///
  /// In hi, this message translates to:
  /// **'थाना'**
  String get fieldPoliceStation;

  /// No description provided for @fieldDistrict.
  ///
  /// In hi, this message translates to:
  /// **'जिला'**
  String get fieldDistrict;

  /// No description provided for @fieldState.
  ///
  /// In hi, this message translates to:
  /// **'राज्य'**
  String get fieldState;

  /// No description provided for @fieldPostalCode.
  ///
  /// In hi, this message translates to:
  /// **'पिन कोड'**
  String get fieldPostalCode;

  /// No description provided for @fieldContactPhone.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क दूरभाष'**
  String get fieldContactPhone;

  /// No description provided for @fieldContactEmail.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क ईमेल'**
  String get fieldContactEmail;

  /// No description provided for @navTempleProfile.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर प्रोफ़ाइल'**
  String get navTempleProfile;

  /// No description provided for @navTempleProfileDesc.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर का नाम, पता, इतिहास और उद्देश्य'**
  String get navTempleProfileDesc;

  /// No description provided for @navCommittee.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंध समिति'**
  String get navCommittee;

  /// No description provided for @navCommitteeDesc.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य, कार्यकाल और सार्वजनिक दृश्यता'**
  String get navCommitteeDesc;

  /// No description provided for @sectionCommittee.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंध समिति'**
  String get sectionCommittee;

  /// No description provided for @sectionHistory.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर का इतिहास'**
  String get sectionHistory;

  /// No description provided for @sectionMission.
  ///
  /// In hi, this message translates to:
  /// **'हमारा उद्देश्य'**
  String get sectionMission;

  /// No description provided for @committeeTitle.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंध समिति'**
  String get committeeTitle;

  /// No description provided for @committeeSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर की देखरेख करने वाले समिति सदस्य।'**
  String get committeeSubtitle;

  /// No description provided for @committeeComingSoon.
  ///
  /// In hi, this message translates to:
  /// **'समिति की जानकारी शीघ्र ही जोड़ी जाएगी।'**
  String get committeeComingSoon;

  /// No description provided for @viewCommittee.
  ///
  /// In hi, this message translates to:
  /// **'पूरी समिति देखें'**
  String get viewCommittee;

  /// Prefix for the panchayat in a rendered address line
  ///
  /// In hi, this message translates to:
  /// **'पंचायत'**
  String get panchayatLabel;

  /// No description provided for @establishedIn.
  ///
  /// In hi, this message translates to:
  /// **'स्थापना: {year}'**
  String establishedIn(int year);

  /// No description provided for @tenureSince.
  ///
  /// In hi, this message translates to:
  /// **'कार्यकाल: {from} से'**
  String tenureSince(String from);

  /// No description provided for @tenureRange.
  ///
  /// In hi, this message translates to:
  /// **'कार्यकाल: {from} – {to}'**
  String tenureRange(String from, String to);

  /// No description provided for @sectionContact.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क विवरण'**
  String get sectionContact;

  /// No description provided for @addressLivesInTempleProfile.
  ///
  /// In hi, this message translates to:
  /// **'पता अब मंदिर प्रोफ़ाइल में रखा जाता है, ताकि वह केवल एक ही स्थान पर रहे।'**
  String get addressLivesInTempleProfile;

  /// No description provided for @templeProfileTitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर प्रोफ़ाइल'**
  String get templeProfileTitle;

  /// No description provided for @templeProfileSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर का नाम, पता और परिचय। यही नाम वेबसाइट के शीर्ष पर दिखाया जाता है।'**
  String get templeProfileSubtitle;

  /// No description provided for @sectionIdentity.
  ///
  /// In hi, this message translates to:
  /// **'पहचान'**
  String get sectionIdentity;

  /// No description provided for @fieldTempleName.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर का नाम'**
  String get fieldTempleName;

  /// No description provided for @fieldHistory.
  ///
  /// In hi, this message translates to:
  /// **'इतिहास'**
  String get fieldHistory;

  /// No description provided for @fieldMission.
  ///
  /// In hi, this message translates to:
  /// **'उद्देश्य'**
  String get fieldMission;

  /// No description provided for @fieldAddressLine1.
  ///
  /// In hi, this message translates to:
  /// **'पता पंक्ति 1'**
  String get fieldAddressLine1;

  /// No description provided for @fieldAddressLine2.
  ///
  /// In hi, this message translates to:
  /// **'पता पंक्ति 2'**
  String get fieldAddressLine2;

  /// No description provided for @fieldCountry.
  ///
  /// In hi, this message translates to:
  /// **'देश'**
  String get fieldCountry;

  /// No description provided for @fieldLogoUrl.
  ///
  /// In hi, this message translates to:
  /// **'लोगो का URL'**
  String get fieldLogoUrl;

  /// No description provided for @fieldMapUrl.
  ///
  /// In hi, this message translates to:
  /// **'मानचित्र का URL'**
  String get fieldMapUrl;

  /// No description provided for @fieldEstablishedYear.
  ///
  /// In hi, this message translates to:
  /// **'स्थापना वर्ष'**
  String get fieldEstablishedYear;

  /// No description provided for @templeNameHint.
  ///
  /// In hi, this message translates to:
  /// **'यह नाम वेबसाइट के शीर्षक, हेडर और फुटर में उपयोग होता है। खाली रहने पर ऐप का डिफ़ॉल्ट नाम दिखेगा।'**
  String get templeNameHint;

  /// No description provided for @committeeAdminTitle.
  ///
  /// In hi, this message translates to:
  /// **'प्रबंध समिति'**
  String get committeeAdminTitle;

  /// No description provided for @committeeAdminSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'समिति सदस्य जोड़ें और तय करें कि उनकी कौन-सी जानकारी सार्वजनिक हो।'**
  String get committeeAdminSubtitle;

  /// No description provided for @committeeEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई सदस्य दर्ज नहीं है।'**
  String get committeeEmpty;

  /// No description provided for @memberNew.
  ///
  /// In hi, this message translates to:
  /// **'नया सदस्य'**
  String get memberNew;

  /// No description provided for @memberEdit.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य संपादित करें'**
  String get memberEdit;

  /// No description provided for @memberCreate.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य जोड़ें'**
  String get memberCreate;

  /// No description provided for @memberCreated.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य जोड़ दिया गया।'**
  String get memberCreated;

  /// No description provided for @memberDeleted.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य हटा दिया गया।'**
  String get memberDeleted;

  /// No description provided for @memberDelete.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य हटाएँ'**
  String get memberDelete;

  /// No description provided for @memberDeleteConfirmTitle.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य हटाएँ?'**
  String get memberDeleteConfirmTitle;

  /// No description provided for @memberDeleteConfirmBody.
  ///
  /// In hi, this message translates to:
  /// **'इससे रिकॉर्ड स्थायी रूप से मिट जाएगा। यदि केवल कार्यकाल समाप्त हुआ है तो \"कार्यकाल समाप्त\" तिथि भरें — रिकॉर्ड सुरक्षित रहेगा।'**
  String get memberDeleteConfirmBody;

  /// No description provided for @memberTenureEnded.
  ///
  /// In hi, this message translates to:
  /// **'कार्यकाल समाप्त'**
  String get memberTenureEnded;

  /// No description provided for @memberNotPublished.
  ///
  /// In hi, this message translates to:
  /// **'अप्रकाशित'**
  String get memberNotPublished;

  /// No description provided for @actionDelete.
  ///
  /// In hi, this message translates to:
  /// **'हटाएँ'**
  String get actionDelete;

  /// No description provided for @fieldName.
  ///
  /// In hi, this message translates to:
  /// **'नाम'**
  String get fieldName;

  /// No description provided for @fieldDesignation.
  ///
  /// In hi, this message translates to:
  /// **'पद'**
  String get fieldDesignation;

  /// No description provided for @fieldBio.
  ///
  /// In hi, this message translates to:
  /// **'परिचय'**
  String get fieldBio;

  /// No description provided for @fieldPhone.
  ///
  /// In hi, this message translates to:
  /// **'दूरभाष'**
  String get fieldPhone;

  /// No description provided for @fieldEmail.
  ///
  /// In hi, this message translates to:
  /// **'ईमेल'**
  String get fieldEmail;

  /// No description provided for @fieldPhotoUrl.
  ///
  /// In hi, this message translates to:
  /// **'फ़ोटो का URL'**
  String get fieldPhotoUrl;

  /// No description provided for @fieldTenureStart.
  ///
  /// In hi, this message translates to:
  /// **'कार्यकाल आरंभ'**
  String get fieldTenureStart;

  /// No description provided for @fieldTenureEnd.
  ///
  /// In hi, this message translates to:
  /// **'कार्यकाल समाप्त'**
  String get fieldTenureEnd;

  /// No description provided for @fieldSortOrder.
  ///
  /// In hi, this message translates to:
  /// **'क्रम'**
  String get fieldSortOrder;

  /// No description provided for @fieldPublished.
  ///
  /// In hi, this message translates to:
  /// **'सार्वजनिक वेबसाइट पर दिखाएँ'**
  String get fieldPublished;

  /// No description provided for @dateHint.
  ///
  /// In hi, this message translates to:
  /// **'YYYY-MM-DD'**
  String get dateHint;

  /// No description provided for @consentTitle.
  ///
  /// In hi, this message translates to:
  /// **'व्यक्तिगत जानकारी की सहमति'**
  String get consentTitle;

  /// No description provided for @consentExplain.
  ///
  /// In hi, this message translates to:
  /// **'दूरभाष, ईमेल और फ़ोटो तभी सार्वजनिक होंगे जब सदस्य की सहमति दर्ज हो। सहमति हटाते ही तीनों तुरंत छिप जाते हैं।'**
  String get consentExplain;

  /// No description provided for @consentRecorded.
  ///
  /// In hi, this message translates to:
  /// **'सदस्य की सहमति दर्ज है'**
  String get consentRecorded;

  /// No description provided for @consentRecordedOn.
  ///
  /// In hi, this message translates to:
  /// **'सहमति दर्ज: {date}'**
  String consentRecordedOn(String date);

  /// No description provided for @consentMissingHint.
  ///
  /// In hi, this message translates to:
  /// **'सहमति दर्ज किए बिना कोई भी व्यक्तिगत विवरण सार्वजनिक नहीं किया जा सकता।'**
  String get consentMissingHint;

  /// No description provided for @showPhonePublicly.
  ///
  /// In hi, this message translates to:
  /// **'दूरभाष सार्वजनिक रूप से दिखाएँ'**
  String get showPhonePublicly;

  /// No description provided for @showEmailPublicly.
  ///
  /// In hi, this message translates to:
  /// **'ईमेल सार्वजनिक रूप से दिखाएँ'**
  String get showEmailPublicly;

  /// No description provided for @showPhotoPublicly.
  ///
  /// In hi, this message translates to:
  /// **'फ़ोटो सार्वजनिक रूप से दिखाएँ'**
  String get showPhotoPublicly;

  /// No description provided for @consentPublicWarning.
  ///
  /// In hi, this message translates to:
  /// **'व्यक्तिगत विवरण सार्वजनिक'**
  String get consentPublicWarning;

  /// No description provided for @sectionTenure.
  ///
  /// In hi, this message translates to:
  /// **'कार्यकाल'**
  String get sectionTenure;
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
