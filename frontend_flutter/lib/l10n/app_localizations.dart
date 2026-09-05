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
  /// **'✨ राधे राधे • जय श्री कृष्ण'**
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
  /// **'मंदिर परिचय'**
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
  /// **'मंदिर समिति'**
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

  /// No description provided for @actionBack.
  ///
  /// In hi, this message translates to:
  /// **'वापस'**
  String get actionBack;

  /// Placeholder for a detail the server did not publish
  ///
  /// In hi, this message translates to:
  /// **'NA'**
  String get valueNotAvailable;

  /// No description provided for @navEvents.
  ///
  /// In hi, this message translates to:
  /// **'पूजा एवं कार्यक्रम'**
  String get navEvents;

  /// No description provided for @navEventsDesc.
  ///
  /// In hi, this message translates to:
  /// **'आरती, भजन-कीर्तन, उत्सव और कैलेंडर'**
  String get navEventsDesc;

  /// No description provided for @eventsTitle.
  ///
  /// In hi, this message translates to:
  /// **'पूजा एवं कार्यक्रम'**
  String get eventsTitle;

  /// No description provided for @eventsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर की दैनिक आरती, साप्ताहिक कीर्तन और आगामी उत्सव।'**
  String get eventsSubtitle;

  /// No description provided for @sectionEvents.
  ///
  /// In hi, this message translates to:
  /// **'आगामी कार्यक्रम'**
  String get sectionEvents;

  /// No description provided for @viewUpcoming.
  ///
  /// In hi, this message translates to:
  /// **'आगामी'**
  String get viewUpcoming;

  /// No description provided for @viewPast.
  ///
  /// In hi, this message translates to:
  /// **'पूर्व कार्यक्रम'**
  String get viewPast;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई आगामी कार्यक्रम निर्धारित नहीं है।'**
  String get noUpcomingEvents;

  /// No description provided for @noPastEvents.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई पूर्व कार्यक्रम दर्ज नहीं है।'**
  String get noPastEvents;

  /// No description provided for @viewAllEvents.
  ///
  /// In hi, this message translates to:
  /// **'सभी कार्यक्रम देखें'**
  String get viewAllEvents;

  /// No description provided for @eventCancelled.
  ///
  /// In hi, this message translates to:
  /// **'रद्द'**
  String get eventCancelled;

  /// No description provided for @eventCancelledNotice.
  ///
  /// In hi, this message translates to:
  /// **'यह कार्यक्रम रद्द कर दिया गया है।'**
  String get eventCancelledNotice;

  /// No description provided for @eventVenue.
  ///
  /// In hi, this message translates to:
  /// **'स्थान'**
  String get eventVenue;

  /// No description provided for @eventUpcomingDates.
  ///
  /// In hi, this message translates to:
  /// **'आगामी तिथियाँ'**
  String get eventUpcomingDates;

  /// No description provided for @eventNotFound.
  ///
  /// In hi, this message translates to:
  /// **'यह कार्यक्रम उपलब्ध नहीं है।'**
  String get eventNotFound;

  /// No description provided for @eventTypeAarti.
  ///
  /// In hi, this message translates to:
  /// **'आरती'**
  String get eventTypeAarti;

  /// No description provided for @eventTypeBhajanKirtan.
  ///
  /// In hi, this message translates to:
  /// **'भजन-कीर्तन'**
  String get eventTypeBhajanKirtan;

  /// No description provided for @eventTypeFestival.
  ///
  /// In hi, this message translates to:
  /// **'उत्सव'**
  String get eventTypeFestival;

  /// No description provided for @eventTypePuja.
  ///
  /// In hi, this message translates to:
  /// **'पूजा'**
  String get eventTypePuja;

  /// No description provided for @eventTypeOther.
  ///
  /// In hi, this message translates to:
  /// **'अन्य'**
  String get eventTypeOther;

  /// No description provided for @recurrenceNone.
  ///
  /// In hi, this message translates to:
  /// **'एक बार'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In hi, this message translates to:
  /// **'प्रतिदिन'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In hi, this message translates to:
  /// **'साप्ताहिक'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In hi, this message translates to:
  /// **'मासिक'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In hi, this message translates to:
  /// **'वार्षिक'**
  String get recurrenceYearly;

  /// No description provided for @weekdayMon.
  ///
  /// In hi, this message translates to:
  /// **'सोम'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In hi, this message translates to:
  /// **'मंगल'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In hi, this message translates to:
  /// **'बुध'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In hi, this message translates to:
  /// **'गुरु'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In hi, this message translates to:
  /// **'शुक्र'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In hi, this message translates to:
  /// **'शनि'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In hi, this message translates to:
  /// **'रवि'**
  String get weekdaySun;

  /// No description provided for @eventsAdminTitle.
  ///
  /// In hi, this message translates to:
  /// **'पूजा एवं कार्यक्रम'**
  String get eventsAdminTitle;

  /// No description provided for @eventsAdminSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'आरती, कीर्तन और उत्सव यहाँ से जोड़ें। दोहराने वाला कार्यक्रम एक ही बार दर्ज करें।'**
  String get eventsAdminSubtitle;

  /// No description provided for @eventsEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई कार्यक्रम दर्ज नहीं है।'**
  String get eventsEmpty;

  /// No description provided for @eventNew.
  ///
  /// In hi, this message translates to:
  /// **'नया कार्यक्रम'**
  String get eventNew;

  /// No description provided for @eventEdit.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम संपादित करें'**
  String get eventEdit;

  /// No description provided for @eventCreate.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम जोड़ें'**
  String get eventCreate;

  /// No description provided for @eventCreated.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम जोड़ दिया गया।'**
  String get eventCreated;

  /// No description provided for @eventDeleted.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम हटा दिया गया।'**
  String get eventDeleted;

  /// No description provided for @eventDelete.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम हटाएँ'**
  String get eventDelete;

  /// No description provided for @eventDeleteConfirmTitle.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम हटाएँ?'**
  String get eventDeleteConfirmTitle;

  /// No description provided for @eventDeleteConfirmBody.
  ///
  /// In hi, this message translates to:
  /// **'इससे रिकॉर्ड स्थायी रूप से मिट जाएगा। यदि कार्यक्रम केवल रद्द हुआ है तो स्थिति \"रद्द\" चुनें — तब भक्तों को सूचना मिलती रहेगी।'**
  String get eventDeleteConfirmBody;

  /// No description provided for @statusCancelled.
  ///
  /// In hi, this message translates to:
  /// **'रद्द'**
  String get statusCancelled;

  /// No description provided for @filterAll.
  ///
  /// In hi, this message translates to:
  /// **'सभी'**
  String get filterAll;

  /// No description provided for @fieldEventType.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम का प्रकार'**
  String get fieldEventType;

  /// No description provided for @fieldEventTitle.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम का नाम'**
  String get fieldEventTitle;

  /// No description provided for @fieldEventDescription.
  ///
  /// In hi, this message translates to:
  /// **'विवरण'**
  String get fieldEventDescription;

  /// No description provided for @fieldVenue.
  ///
  /// In hi, this message translates to:
  /// **'स्थान'**
  String get fieldVenue;

  /// No description provided for @fieldStartAt.
  ///
  /// In hi, this message translates to:
  /// **'आरंभ'**
  String get fieldStartAt;

  /// No description provided for @fieldEndAt.
  ///
  /// In hi, this message translates to:
  /// **'समाप्ति'**
  String get fieldEndAt;

  /// No description provided for @fieldRecurrence.
  ///
  /// In hi, this message translates to:
  /// **'दोहराव'**
  String get fieldRecurrence;

  /// No description provided for @fieldRecurrenceDays.
  ///
  /// In hi, this message translates to:
  /// **'किन दिनों'**
  String get fieldRecurrenceDays;

  /// No description provided for @fieldRecurrenceUntil.
  ///
  /// In hi, this message translates to:
  /// **'इस तिथि तक'**
  String get fieldRecurrenceUntil;

  /// No description provided for @fieldPosterUrl.
  ///
  /// In hi, this message translates to:
  /// **'पोस्टर का URL'**
  String get fieldPosterUrl;

  /// No description provided for @fieldFeatured.
  ///
  /// In hi, this message translates to:
  /// **'मुख पृष्ठ पर दिखाएँ'**
  String get fieldFeatured;

  /// No description provided for @recurringHint.
  ///
  /// In hi, this message translates to:
  /// **'दोहराने वाला कार्यक्रम एक ही बार दर्ज होता है — दैनिक आरती के लिए 365 प्रविष्टियाँ नहीं बनानी पड़तीं।'**
  String get recurringHint;

  /// No description provided for @pickDate.
  ///
  /// In hi, this message translates to:
  /// **'तिथि चुनें'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In hi, this message translates to:
  /// **'समय चुनें'**
  String get pickTime;

  /// No description provided for @clearEndTime.
  ///
  /// In hi, this message translates to:
  /// **'समाप्ति हटाएँ'**
  String get clearEndTime;

  /// No description provided for @viewEvents.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम देखें'**
  String get viewEvents;

  /// No description provided for @navGallery.
  ///
  /// In hi, this message translates to:
  /// **'गैलरी'**
  String get navGallery;

  /// No description provided for @galleryTitle.
  ///
  /// In hi, this message translates to:
  /// **'फोटो गैलरी'**
  String get galleryTitle;

  /// No description provided for @gallerySubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर, पूजा, त्योहार और ग्राम कार्यक्रमों की तस्वीरें यहाँ दिखाई जाएंगी।'**
  String get gallerySubtitle;

  /// No description provided for @sectionGallery.
  ///
  /// In hi, this message translates to:
  /// **'फोटो गैलरी'**
  String get sectionGallery;

  /// No description provided for @viewGallery.
  ///
  /// In hi, this message translates to:
  /// **'पूरी गैलरी देखें'**
  String get viewGallery;

  /// No description provided for @galleryPhotos.
  ///
  /// In hi, this message translates to:
  /// **'तस्वीरें'**
  String get galleryPhotos;

  /// No description provided for @galleryVideos.
  ///
  /// In hi, this message translates to:
  /// **'वीडियो दर्शन'**
  String get galleryVideos;

  /// No description provided for @galleryAllAlbums.
  ///
  /// In hi, this message translates to:
  /// **'सभी'**
  String get galleryAllAlbums;

  /// No description provided for @noPhotos.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई तस्वीर प्रकाशित नहीं हुई है।'**
  String get noPhotos;

  /// No description provided for @noVideos.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई वीडियो दर्शन उपलब्ध नहीं है।'**
  String get noVideos;

  /// No description provided for @galleryLoadMore.
  ///
  /// In hi, this message translates to:
  /// **'और तस्वीरें दिखाएँ'**
  String get galleryLoadMore;

  /// No description provided for @imageUnavailable.
  ///
  /// In hi, this message translates to:
  /// **'चित्र लोड नहीं हो सका'**
  String get imageUnavailable;

  /// No description provided for @actionClose.
  ///
  /// In hi, this message translates to:
  /// **'बंद करें'**
  String get actionClose;

  /// No description provided for @openInYoutube.
  ///
  /// In hi, this message translates to:
  /// **'यूट्यूब पर देखें'**
  String get openInYoutube;

  /// No description provided for @videoDarshanNotice.
  ///
  /// In hi, this message translates to:
  /// **'वीडियो यूट्यूब पर होस्ट है; चलाने पर यूट्यूब की शर्तें लागू होंगी।'**
  String get videoDarshanNotice;

  /// No description provided for @navMedia.
  ///
  /// In hi, this message translates to:
  /// **'गैलरी एवं वीडियो'**
  String get navMedia;

  /// No description provided for @navMediaDesc.
  ///
  /// In hi, this message translates to:
  /// **'तस्वीरें और वीडियो अपलोड, प्रकाशित और क्रमबद्ध करें'**
  String get navMediaDesc;

  /// No description provided for @mediaAdminTitle.
  ///
  /// In hi, this message translates to:
  /// **'गैलरी एवं वीडियो'**
  String get mediaAdminTitle;

  /// No description provided for @mediaAdminSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'तस्वीरें यहाँ अपलोड करें और वीडियो लिंक जोड़ें। अपलोड की गई हर तस्वीर से स्थान एवं कैमरा जानकारी स्वतः हटा दी जाती है।'**
  String get mediaAdminSubtitle;

  /// No description provided for @mediaEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई मीडिया नहीं जोड़ा गया है।'**
  String get mediaEmpty;

  /// No description provided for @mediaNew.
  ///
  /// In hi, this message translates to:
  /// **'नया मीडिया'**
  String get mediaNew;

  /// No description provided for @mediaEdit.
  ///
  /// In hi, this message translates to:
  /// **'मीडिया संपादित करें'**
  String get mediaEdit;

  /// No description provided for @mediaUploadPhoto.
  ///
  /// In hi, this message translates to:
  /// **'तस्वीर अपलोड करें'**
  String get mediaUploadPhoto;

  /// No description provided for @mediaAddVideo.
  ///
  /// In hi, this message translates to:
  /// **'वीडियो लिंक जोड़ें'**
  String get mediaAddVideo;

  /// No description provided for @mediaChooseFile.
  ///
  /// In hi, this message translates to:
  /// **'फ़ाइल चुनें'**
  String get mediaChooseFile;

  /// No description provided for @mediaFileHint.
  ///
  /// In hi, this message translates to:
  /// **'JPEG, PNG या WebP · अधिकतम {size} MB'**
  String mediaFileHint(int size);

  /// No description provided for @mediaNoFileChosen.
  ///
  /// In hi, this message translates to:
  /// **'कोई फ़ाइल नहीं चुनी गई'**
  String get mediaNoFileChosen;

  /// No description provided for @mediaFileSelected.
  ///
  /// In hi, this message translates to:
  /// **'{name} · {size}'**
  String mediaFileSelected(String name, String size);

  /// No description provided for @mediaFileRequired.
  ///
  /// In hi, this message translates to:
  /// **'अपलोड करने के लिए एक तस्वीर चुनें।'**
  String get mediaFileRequired;

  /// No description provided for @mediaChooserUnavailable.
  ///
  /// In hi, this message translates to:
  /// **'फ़ाइल चयन केवल ब्राउज़र में उपलब्ध है।'**
  String get mediaChooserUnavailable;

  /// No description provided for @mediaTypePhoto.
  ///
  /// In hi, this message translates to:
  /// **'तस्वीर'**
  String get mediaTypePhoto;

  /// No description provided for @mediaTypeVideo.
  ///
  /// In hi, this message translates to:
  /// **'वीडियो'**
  String get mediaTypeVideo;

  /// No description provided for @mediaDelete.
  ///
  /// In hi, this message translates to:
  /// **'मीडिया हटाएँ'**
  String get mediaDelete;

  /// No description provided for @mediaDeleteConfirmTitle.
  ///
  /// In hi, this message translates to:
  /// **'यह मीडिया हटाएँ?'**
  String get mediaDeleteConfirmTitle;

  /// No description provided for @mediaDeleteConfirmBody.
  ///
  /// In hi, this message translates to:
  /// **'फ़ाइल स्थायी रूप से मिट जाएगी। यदि इसे केवल छिपाना है तो प्रकाशन हटाएँ।'**
  String get mediaDeleteConfirmBody;

  /// No description provided for @mediaDeleted.
  ///
  /// In hi, this message translates to:
  /// **'मीडिया हटा दिया गया।'**
  String get mediaDeleted;

  /// No description provided for @mediaInUseTitle.
  ///
  /// In hi, this message translates to:
  /// **'यह फ़ाइल अभी उपयोग में है'**
  String get mediaInUseTitle;

  /// No description provided for @mediaInUseBody.
  ///
  /// In hi, this message translates to:
  /// **'नीचे दिए गए स्थानों से हटाने के बाद ही इसे मिटाया जा सकता है। तब तक इसका प्रकाशन हटाया जा सकता है।'**
  String get mediaInUseBody;

  /// No description provided for @mediaReferenceEventPoster.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम पोस्टर'**
  String get mediaReferenceEventPoster;

  /// No description provided for @mediaReferenceCommitteeMember.
  ///
  /// In hi, this message translates to:
  /// **'समिति सदस्य'**
  String get mediaReferenceCommitteeMember;

  /// No description provided for @mediaReferenceTempleLogo.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर का लोगो'**
  String get mediaReferenceTempleLogo;

  /// No description provided for @mediaReferenceAlbumCover.
  ///
  /// In hi, this message translates to:
  /// **'एल्बम कवर'**
  String get mediaReferenceAlbumCover;

  /// No description provided for @mediaReferencePage.
  ///
  /// In hi, this message translates to:
  /// **'पृष्ठ'**
  String get mediaReferencePage;

  /// No description provided for @mediaMoveUp.
  ///
  /// In hi, this message translates to:
  /// **'ऊपर ले जाएँ'**
  String get mediaMoveUp;

  /// No description provided for @mediaMoveDown.
  ///
  /// In hi, this message translates to:
  /// **'नीचे ले जाएँ'**
  String get mediaMoveDown;

  /// No description provided for @mediaOrderSaved.
  ///
  /// In hi, this message translates to:
  /// **'क्रम सहेजा गया।'**
  String get mediaOrderSaved;

  /// No description provided for @fieldCaptionHindi.
  ///
  /// In hi, this message translates to:
  /// **'कैप्शन (हिन्दी)'**
  String get fieldCaptionHindi;

  /// No description provided for @fieldCaptionEnglish.
  ///
  /// In hi, this message translates to:
  /// **'कैप्शन (अंग्रेज़ी)'**
  String get fieldCaptionEnglish;

  /// No description provided for @fieldVideoUrl.
  ///
  /// In hi, this message translates to:
  /// **'यूट्यूब लिंक'**
  String get fieldVideoUrl;

  /// No description provided for @videoUrlHint.
  ///
  /// In hi, this message translates to:
  /// **'केवल यूट्यूब लिंक जोड़े जा सकते हैं।'**
  String get videoUrlHint;

  /// No description provided for @navAlbums.
  ///
  /// In hi, this message translates to:
  /// **'एल्बम'**
  String get navAlbums;

  /// No description provided for @navAlbumsDesc.
  ///
  /// In hi, this message translates to:
  /// **'तस्वीरों को त्योहार या अवसर के अनुसार समूह में रखें'**
  String get navAlbumsDesc;

  /// No description provided for @albumsAdminTitle.
  ///
  /// In hi, this message translates to:
  /// **'एल्बम'**
  String get albumsAdminTitle;

  /// No description provided for @albumsAdminSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'तस्वीरों को त्योहार या अवसर के अनुसार समूह में रखें। एल्बम हटाने पर तस्वीरें बनी रहती हैं।'**
  String get albumsAdminSubtitle;

  /// No description provided for @albumsEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई एल्बम नहीं बनाया गया है।'**
  String get albumsEmpty;

  /// No description provided for @albumNew.
  ///
  /// In hi, this message translates to:
  /// **'नया एल्बम'**
  String get albumNew;

  /// No description provided for @albumEdit.
  ///
  /// In hi, this message translates to:
  /// **'एल्बम संपादित करें'**
  String get albumEdit;

  /// No description provided for @albumDelete.
  ///
  /// In hi, this message translates to:
  /// **'एल्बम हटाएँ'**
  String get albumDelete;

  /// No description provided for @albumDeleteConfirmTitle.
  ///
  /// In hi, this message translates to:
  /// **'यह एल्बम हटाएँ?'**
  String get albumDeleteConfirmTitle;

  /// No description provided for @albumDeleteConfirmBody.
  ///
  /// In hi, this message translates to:
  /// **'एल्बम हट जाएगा, पर उसकी तस्वीरें बनी रहेंगी।'**
  String get albumDeleteConfirmBody;

  /// No description provided for @albumDeleted.
  ///
  /// In hi, this message translates to:
  /// **'एल्बम हटा दिया गया।'**
  String get albumDeleted;

  /// No description provided for @albumNone.
  ///
  /// In hi, this message translates to:
  /// **'किसी एल्बम में नहीं'**
  String get albumNone;

  /// No description provided for @albumItemCount.
  ///
  /// In hi, this message translates to:
  /// **'{count} तस्वीरें'**
  String albumItemCount(int count);

  /// No description provided for @fieldAlbum.
  ///
  /// In hi, this message translates to:
  /// **'एल्बम'**
  String get fieldAlbum;

  /// No description provided for @fieldSlug.
  ///
  /// In hi, this message translates to:
  /// **'यूआरएल नाम'**
  String get fieldSlug;

  /// No description provided for @slugHint.
  ///
  /// In hi, this message translates to:
  /// **'खाली छोड़ने पर स्वतः बना दिया जाएगा।'**
  String get slugHint;

  /// No description provided for @fieldDescriptionHindi.
  ///
  /// In hi, this message translates to:
  /// **'विवरण (हिन्दी)'**
  String get fieldDescriptionHindi;

  /// No description provided for @fieldDescriptionEnglish.
  ///
  /// In hi, this message translates to:
  /// **'विवरण (अंग्रेज़ी)'**
  String get fieldDescriptionEnglish;

  /// No description provided for @fieldCoverPhoto.
  ///
  /// In hi, this message translates to:
  /// **'कवर तस्वीर'**
  String get fieldCoverPhoto;

  /// No description provided for @mediaPickerChoose.
  ///
  /// In hi, this message translates to:
  /// **'गैलरी से चुनें'**
  String get mediaPickerChoose;

  /// No description provided for @mediaPickerClear.
  ///
  /// In hi, this message translates to:
  /// **'हटाएँ'**
  String get mediaPickerClear;

  /// No description provided for @mediaPickerEmpty.
  ///
  /// In hi, this message translates to:
  /// **'गैलरी में अभी कोई प्रकाशित तस्वीर नहीं है।'**
  String get mediaPickerEmpty;

  /// No description provided for @mediaPickerHint.
  ///
  /// In hi, this message translates to:
  /// **'गैलरी से चुनें, या नीचे कोई बाहरी यूआरएल लिखें।'**
  String get mediaPickerHint;

  /// No description provided for @navDonate.
  ///
  /// In hi, this message translates to:
  /// **'दान'**
  String get navDonate;

  /// No description provided for @donateTitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर सहयोग / दान'**
  String get donateTitle;

  /// No description provided for @donateSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'आपका सहयोग मंदिर की पूजा व्यवस्था, रखरखाव, त्योहार और सेवा कार्यों में उपयोग होगा।'**
  String get donateSubtitle;

  /// No description provided for @donateHeading.
  ///
  /// In hi, this message translates to:
  /// **'पारदर्शी एवं सामुदायिक दान व्यवस्था'**
  String get donateHeading;

  /// No description provided for @donateComingSoon.
  ///
  /// In hi, this message translates to:
  /// **'दान संबंधी जानकारी शीघ्र ही यहाँ जोड़ी जाएगी।'**
  String get donateComingSoon;

  /// No description provided for @donateAction.
  ///
  /// In hi, this message translates to:
  /// **'दान करें'**
  String get donateAction;

  /// No description provided for @viewDonate.
  ///
  /// In hi, this message translates to:
  /// **'दान विवरण देखें'**
  String get viewDonate;

  /// No description provided for @fieldUpiId.
  ///
  /// In hi, this message translates to:
  /// **'UPI ID'**
  String get fieldUpiId;

  /// No description provided for @fieldBankName.
  ///
  /// In hi, this message translates to:
  /// **'बैंक'**
  String get fieldBankName;

  /// No description provided for @fieldAccountName.
  ///
  /// In hi, this message translates to:
  /// **'खाता नाम'**
  String get fieldAccountName;

  /// No description provided for @fieldAccountNumber.
  ///
  /// In hi, this message translates to:
  /// **'खाता संख्या'**
  String get fieldAccountNumber;

  /// No description provided for @fieldIfsc.
  ///
  /// In hi, this message translates to:
  /// **'IFSC'**
  String get fieldIfsc;

  /// No description provided for @donateQrLabel.
  ///
  /// In hi, this message translates to:
  /// **'UPI QR'**
  String get donateQrLabel;

  /// No description provided for @donateCopied.
  ///
  /// In hi, this message translates to:
  /// **'{label} कॉपी हो गया।'**
  String donateCopied(String label);

  /// No description provided for @actionCopy.
  ///
  /// In hi, this message translates to:
  /// **'कॉपी करें'**
  String get actionCopy;

  /// No description provided for @navDonations.
  ///
  /// In hi, this message translates to:
  /// **'दान एवं रसीदें'**
  String get navDonations;

  /// No description provided for @navDonationsDesc.
  ///
  /// In hi, this message translates to:
  /// **'दान दर्ज करें, सत्यापित करें और रसीद जारी करें'**
  String get navDonationsDesc;

  /// No description provided for @donationsAdminTitle.
  ///
  /// In hi, this message translates to:
  /// **'दान एवं रसीदें'**
  String get donationsAdminTitle;

  /// No description provided for @donationsAdminSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'दान यहाँ दर्ज करें। सत्यापन के बाद रसीद संख्या जारी होती है और उसके बाद विवरण नहीं बदला जा सकता।'**
  String get donationsAdminSubtitle;

  /// No description provided for @donationsEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई दान दर्ज नहीं किया गया है।'**
  String get donationsEmpty;

  /// No description provided for @donationNew.
  ///
  /// In hi, this message translates to:
  /// **'नया दान दर्ज करें'**
  String get donationNew;

  /// No description provided for @donationEdit.
  ///
  /// In hi, this message translates to:
  /// **'दान विवरण'**
  String get donationEdit;

  /// No description provided for @donationSearchHint.
  ///
  /// In hi, this message translates to:
  /// **'नाम, रसीद संख्या या संदर्भ खोजें'**
  String get donationSearchHint;

  /// No description provided for @summaryReceived.
  ///
  /// In hi, this message translates to:
  /// **'कुल प्राप्त दान'**
  String get summaryReceived;

  /// No description provided for @summaryPending.
  ///
  /// In hi, this message translates to:
  /// **'सत्यापन शेष'**
  String get summaryPending;

  /// No description provided for @summaryDonors.
  ///
  /// In hi, this message translates to:
  /// **'दानदाता'**
  String get summaryDonors;

  /// No description provided for @summaryReversed.
  ///
  /// In hi, this message translates to:
  /// **'निरस्त'**
  String get summaryReversed;

  /// No description provided for @statusPending.
  ///
  /// In hi, this message translates to:
  /// **'सत्यापन शेष'**
  String get statusPending;

  /// No description provided for @statusReversed.
  ///
  /// In hi, this message translates to:
  /// **'निरस्त'**
  String get statusReversed;

  /// No description provided for @statusConfirmed.
  ///
  /// In hi, this message translates to:
  /// **'सत्यापित'**
  String get statusConfirmed;

  /// No description provided for @fieldDonorName.
  ///
  /// In hi, this message translates to:
  /// **'दानदाता का नाम'**
  String get fieldDonorName;

  /// No description provided for @fieldDonorPhone.
  ///
  /// In hi, this message translates to:
  /// **'दूरभाष'**
  String get fieldDonorPhone;

  /// No description provided for @fieldDonorAddress.
  ///
  /// In hi, this message translates to:
  /// **'पता'**
  String get fieldDonorAddress;

  /// No description provided for @fieldAmount.
  ///
  /// In hi, this message translates to:
  /// **'राशि (₹)'**
  String get fieldAmount;

  /// No description provided for @amountHint.
  ///
  /// In hi, this message translates to:
  /// **'जैसे 501 या 501.50'**
  String get amountHint;

  /// No description provided for @fieldDonationDate.
  ///
  /// In hi, this message translates to:
  /// **'दान की तिथि'**
  String get fieldDonationDate;

  /// No description provided for @fieldPaymentMode.
  ///
  /// In hi, this message translates to:
  /// **'भुगतान माध्यम'**
  String get fieldPaymentMode;

  /// No description provided for @fieldReferenceNumber.
  ///
  /// In hi, this message translates to:
  /// **'संदर्भ संख्या'**
  String get fieldReferenceNumber;

  /// No description provided for @referenceHint.
  ///
  /// In hi, this message translates to:
  /// **'नकद के अलावा हर माध्यम के लिए आवश्यक — UPI संदर्भ, चेक संख्या या ट्रांसफर आईडी।'**
  String get referenceHint;

  /// No description provided for @fieldPurpose.
  ///
  /// In hi, this message translates to:
  /// **'उद्देश्य'**
  String get fieldPurpose;

  /// No description provided for @fieldNotes.
  ///
  /// In hi, this message translates to:
  /// **'टिप्पणी'**
  String get fieldNotes;

  /// No description provided for @fieldAnonymous.
  ///
  /// In hi, this message translates to:
  /// **'दानदाता का नाम सार्वजनिक न करें'**
  String get fieldAnonymous;

  /// No description provided for @anonymousHint.
  ///
  /// In hi, this message translates to:
  /// **'रसीद पर नाम फिर भी रहेगा — वह दानदाता की अपनी रसीद है।'**
  String get anonymousHint;

  /// No description provided for @modeCash.
  ///
  /// In hi, this message translates to:
  /// **'नकद'**
  String get modeCash;

  /// No description provided for @modeUpi.
  ///
  /// In hi, this message translates to:
  /// **'UPI'**
  String get modeUpi;

  /// No description provided for @modeBankTransfer.
  ///
  /// In hi, this message translates to:
  /// **'बैंक ट्रांसफर'**
  String get modeBankTransfer;

  /// No description provided for @modeCheque.
  ///
  /// In hi, this message translates to:
  /// **'चेक'**
  String get modeCheque;

  /// No description provided for @modeCard.
  ///
  /// In hi, this message translates to:
  /// **'कार्ड'**
  String get modeCard;

  /// No description provided for @modeOther.
  ///
  /// In hi, this message translates to:
  /// **'अन्य'**
  String get modeOther;

  /// No description provided for @purposeGeneral.
  ///
  /// In hi, this message translates to:
  /// **'सामान्य'**
  String get purposeGeneral;

  /// No description provided for @purposePuja.
  ///
  /// In hi, this message translates to:
  /// **'पूजा व्यवस्था'**
  String get purposePuja;

  /// No description provided for @purposeMaintenance.
  ///
  /// In hi, this message translates to:
  /// **'रखरखाव'**
  String get purposeMaintenance;

  /// No description provided for @purposeFestival.
  ///
  /// In hi, this message translates to:
  /// **'त्योहार'**
  String get purposeFestival;

  /// No description provided for @purposeAnnadan.
  ///
  /// In hi, this message translates to:
  /// **'भंडारा एवं प्रसाद'**
  String get purposeAnnadan;

  /// No description provided for @purposeConstruction.
  ///
  /// In hi, this message translates to:
  /// **'निर्माण कार्य'**
  String get purposeConstruction;

  /// No description provided for @purposeOther.
  ///
  /// In hi, this message translates to:
  /// **'अन्य'**
  String get purposeOther;

  /// No description provided for @fieldReceiptNumber.
  ///
  /// In hi, this message translates to:
  /// **'रसीद संख्या'**
  String get fieldReceiptNumber;

  /// No description provided for @receiptNotIssued.
  ///
  /// In hi, this message translates to:
  /// **'सत्यापन के बाद जारी होगी'**
  String get receiptNotIssued;

  /// No description provided for @donationConfirm.
  ///
  /// In hi, this message translates to:
  /// **'सत्यापित करें'**
  String get donationConfirm;

  /// No description provided for @donationConfirmTitle.
  ///
  /// In hi, this message translates to:
  /// **'इस दान को सत्यापित करें?'**
  String get donationConfirmTitle;

  /// No description provided for @donationConfirmBody.
  ///
  /// In hi, this message translates to:
  /// **'सत्यापित करते ही रसीद संख्या जारी हो जाएगी और उसके बाद राशि, तिथि या दानदाता का नाम नहीं बदला जा सकेगा।'**
  String get donationConfirmBody;

  /// No description provided for @donationConfirmed.
  ///
  /// In hi, this message translates to:
  /// **'दान सत्यापित। रसीद संख्या {receipt} जारी हुई।'**
  String donationConfirmed(String receipt);

  /// No description provided for @donationReverse.
  ///
  /// In hi, this message translates to:
  /// **'दान निरस्त करें'**
  String get donationReverse;

  /// No description provided for @donationReverseTitle.
  ///
  /// In hi, this message translates to:
  /// **'इस दान को निरस्त करें?'**
  String get donationReverseTitle;

  /// No description provided for @donationReverseBody.
  ///
  /// In hi, this message translates to:
  /// **'प्रविष्टि मिटाई नहीं जाती — वह रसीद संख्या सहित बनी रहती है और किसी योग में नहीं गिनी जाती। कारण लिखना आवश्यक है।'**
  String get donationReverseBody;

  /// No description provided for @fieldReversalReason.
  ///
  /// In hi, this message translates to:
  /// **'निरस्त करने का कारण'**
  String get fieldReversalReason;

  /// No description provided for @donationReversed.
  ///
  /// In hi, this message translates to:
  /// **'दान निरस्त कर दिया गया।'**
  String get donationReversed;

  /// No description provided for @donationRecorded.
  ///
  /// In hi, this message translates to:
  /// **'दान दर्ज हो गया।'**
  String get donationRecorded;

  /// No description provided for @donationPrintReceipt.
  ///
  /// In hi, this message translates to:
  /// **'रसीद प्रिंट करें'**
  String get donationPrintReceipt;

  /// No description provided for @donationLockedNotice.
  ///
  /// In hi, this message translates to:
  /// **'रसीद जारी हो चुकी है, इसलिए अब केवल टिप्पणी बदली जा सकती है। सुधार के लिए इसे निरस्त करके दोबारा दर्ज करें।'**
  String get donationLockedNotice;

  /// No description provided for @donationReversedNotice.
  ///
  /// In hi, this message translates to:
  /// **'यह दान {date} को निरस्त किया गया: {reason}'**
  String donationReversedNotice(String date, String reason);

  /// No description provided for @recordedByLabel.
  ///
  /// In hi, this message translates to:
  /// **'दर्ज किया'**
  String get recordedByLabel;

  /// No description provided for @confirmedByLabel.
  ///
  /// In hi, this message translates to:
  /// **'सत्यापित किया'**
  String get confirmedByLabel;

  /// No description provided for @navDonationSettings.
  ///
  /// In hi, this message translates to:
  /// **'दान विवरण'**
  String get navDonationSettings;

  /// No description provided for @navDonationSettingsDesc.
  ///
  /// In hi, this message translates to:
  /// **'UPI, बैंक विवरण और QR जो वेबसाइट पर दिखते हैं'**
  String get navDonationSettingsDesc;

  /// No description provided for @donationSettingsTitle.
  ///
  /// In hi, this message translates to:
  /// **'दान विवरण'**
  String get donationSettingsTitle;

  /// No description provided for @donationSettingsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'ये विवरण वेबसाइट के दान अनुभाग में दिखाई देते हैं। खाता संख्या ठीक वैसी ही दिखेगी जैसी यहाँ लिखी जाए — छिपाना है तो स्वयं छिपाकर लिखें।'**
  String get donationSettingsSubtitle;

  /// No description provided for @donationSettingsSaved.
  ///
  /// In hi, this message translates to:
  /// **'दान विवरण सहेज दिए गए।'**
  String get donationSettingsSaved;

  /// No description provided for @fieldQrImage.
  ///
  /// In hi, this message translates to:
  /// **'UPI QR चित्र'**
  String get fieldQrImage;

  /// No description provided for @fieldDonateIntroHindi.
  ///
  /// In hi, this message translates to:
  /// **'परिचय (हिन्दी)'**
  String get fieldDonateIntroHindi;

  /// No description provided for @fieldDonateIntroEnglish.
  ///
  /// In hi, this message translates to:
  /// **'परिचय (अंग्रेज़ी)'**
  String get fieldDonateIntroEnglish;

  /// No description provided for @fieldDonateNoteHindi.
  ///
  /// In hi, this message translates to:
  /// **'सूचना (हिन्दी)'**
  String get fieldDonateNoteHindi;

  /// No description provided for @fieldDonateNoteEnglish.
  ///
  /// In hi, this message translates to:
  /// **'सूचना (अंग्रेज़ी)'**
  String get fieldDonateNoteEnglish;

  /// No description provided for @fieldPublishDonationDetails.
  ///
  /// In hi, this message translates to:
  /// **'वेबसाइट पर दिखाएँ'**
  String get fieldPublishDonationDetails;

  /// No description provided for @donationSettingsIncomplete.
  ///
  /// In hi, this message translates to:
  /// **'प्रकाशित है, पर कोई भुगतान विवरण नहीं भरा गया — इसलिए वेबसाइट पर कुछ नहीं दिखेगा।'**
  String get donationSettingsIncomplete;

  /// No description provided for @mediaReferenceDonationQr.
  ///
  /// In hi, this message translates to:
  /// **'दान QR'**
  String get mediaReferenceDonationQr;

  /// No description provided for @errorDonationLocked.
  ///
  /// In hi, this message translates to:
  /// **'यह प्रविष्टि अब बदली नहीं जा सकती।'**
  String get errorDonationLocked;

  /// No description provided for @paginationPage.
  ///
  /// In hi, this message translates to:
  /// **'पृष्ठ {current} / {last}'**
  String paginationPage(int current, int last);

  /// No description provided for @actionPrevious.
  ///
  /// In hi, this message translates to:
  /// **'पिछला'**
  String get actionPrevious;

  /// No description provided for @actionNext.
  ///
  /// In hi, this message translates to:
  /// **'अगला'**
  String get actionNext;

  /// No description provided for @contactPageTitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर को लिखें'**
  String get contactPageTitle;

  /// No description provided for @contactPageSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'पूजा, कार्यक्रम या किसी भी विषय में पूछें। समिति का कोई सदस्य आपसे संपर्क करेगा।'**
  String get contactPageSubtitle;

  /// No description provided for @contactFormTitle.
  ///
  /// In hi, this message translates to:
  /// **'संदेश भेजें'**
  String get contactFormTitle;

  /// No description provided for @contactOtherWays.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क के अन्य माध्यम'**
  String get contactOtherWays;

  /// No description provided for @contactOpenForm.
  ///
  /// In hi, this message translates to:
  /// **'समिति को लिखें'**
  String get contactOpenForm;

  /// No description provided for @fieldYourName.
  ///
  /// In hi, this message translates to:
  /// **'आपका नाम'**
  String get fieldYourName;

  /// No description provided for @fieldEnquiryCategory.
  ///
  /// In hi, this message translates to:
  /// **'विषय क्या है?'**
  String get fieldEnquiryCategory;

  /// No description provided for @fieldEnquiryMessage.
  ///
  /// In hi, this message translates to:
  /// **'आपका संदेश'**
  String get fieldEnquiryMessage;

  /// No description provided for @fieldPreferredLanguage.
  ///
  /// In hi, this message translates to:
  /// **'उत्तर किस भाषा में चाहिए'**
  String get fieldPreferredLanguage;

  /// No description provided for @contactChannelHint.
  ///
  /// In hi, this message translates to:
  /// **'मोबाइल नंबर या ईमेल अवश्य दें, ताकि समिति उत्तर दे सके।'**
  String get contactChannelHint;

  /// No description provided for @actionSendMessage.
  ///
  /// In hi, this message translates to:
  /// **'संदेश भेजें'**
  String get actionSendMessage;

  /// No description provided for @actionSendAnother.
  ///
  /// In hi, this message translates to:
  /// **'एक और संदेश भेजें'**
  String get actionSendAnother;

  /// No description provided for @enquirySentTitle.
  ///
  /// In hi, this message translates to:
  /// **'आपका संदेश भेज दिया गया है'**
  String get enquirySentTitle;

  /// No description provided for @enquirySentBody.
  ///
  /// In hi, this message translates to:
  /// **'समिति का कोई सदस्य शीघ्र ही संपर्क करेगा। यह संदर्भ संख्या सुरक्षित रखें — इसी से मंदिर आपका संदेश ढूँढ़ेगा।'**
  String get enquirySentBody;

  /// No description provided for @enquiryReferenceLabel.
  ///
  /// In hi, this message translates to:
  /// **'संदर्भ संख्या'**
  String get enquiryReferenceLabel;

  /// No description provided for @enquiryChallengeLabel.
  ///
  /// In hi, this message translates to:
  /// **'भेजने से पहले एक छोटा सा प्रश्न'**
  String get enquiryChallengeLabel;

  /// No description provided for @fieldChallengeAnswer.
  ///
  /// In hi, this message translates to:
  /// **'आपका उत्तर'**
  String get fieldChallengeAnswer;

  /// No description provided for @enquiryCategoryGeneral.
  ///
  /// In hi, this message translates to:
  /// **'सामान्य जानकारी'**
  String get enquiryCategoryGeneral;

  /// No description provided for @enquiryCategoryPujaBooking.
  ///
  /// In hi, this message translates to:
  /// **'पूजा बुकिंग'**
  String get enquiryCategoryPujaBooking;

  /// No description provided for @enquiryCategoryDonation.
  ///
  /// In hi, this message translates to:
  /// **'दान संबंधी'**
  String get enquiryCategoryDonation;

  /// No description provided for @enquiryCategoryEvent.
  ///
  /// In hi, this message translates to:
  /// **'कार्यक्रम संबंधी'**
  String get enquiryCategoryEvent;

  /// No description provided for @enquiryCategoryVolunteer.
  ///
  /// In hi, this message translates to:
  /// **'सेवा एवं सहयोग'**
  String get enquiryCategoryVolunteer;

  /// No description provided for @enquiryCategorySuggestion.
  ///
  /// In hi, this message translates to:
  /// **'सुझाव'**
  String get enquiryCategorySuggestion;

  /// No description provided for @enquiryCategoryComplaint.
  ///
  /// In hi, this message translates to:
  /// **'शिकायत'**
  String get enquiryCategoryComplaint;

  /// No description provided for @enquiryCategoryOther.
  ///
  /// In hi, this message translates to:
  /// **'अन्य'**
  String get enquiryCategoryOther;

  /// No description provided for @enquiryStatusNew.
  ///
  /// In hi, this message translates to:
  /// **'नया'**
  String get enquiryStatusNew;

  /// No description provided for @enquiryStatusInProgress.
  ///
  /// In hi, this message translates to:
  /// **'कार्यवाही में'**
  String get enquiryStatusInProgress;

  /// No description provided for @enquiryStatusResolved.
  ///
  /// In hi, this message translates to:
  /// **'उत्तर दिया गया'**
  String get enquiryStatusResolved;

  /// No description provided for @enquiryStatusSpam.
  ///
  /// In hi, this message translates to:
  /// **'स्पैम'**
  String get enquiryStatusSpam;

  /// No description provided for @navEnquiries.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क एवं पूछताछ'**
  String get navEnquiries;

  /// No description provided for @navEnquiriesDesc.
  ///
  /// In hi, this message translates to:
  /// **'भक्तों द्वारा भेजे गए संदेश और उन पर की गई कार्यवाही'**
  String get navEnquiriesDesc;

  /// No description provided for @enquiryInboxTitle.
  ///
  /// In hi, this message translates to:
  /// **'पूछताछ इनबॉक्स'**
  String get enquiryInboxTitle;

  /// No description provided for @enquiryInboxSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क फ़ॉर्म से आए संदेश। इनमें से कुछ भी सार्वजनिक वेबसाइट पर नहीं दिखता।'**
  String get enquiryInboxSubtitle;

  /// No description provided for @enquiryInboxEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी तक कोई संदेश नहीं।'**
  String get enquiryInboxEmpty;

  /// No description provided for @enquiryDetailTitle.
  ///
  /// In hi, this message translates to:
  /// **'पूछताछ'**
  String get enquiryDetailTitle;

  /// No description provided for @enquiryAssignedTo.
  ///
  /// In hi, this message translates to:
  /// **'सौंपा गया'**
  String get enquiryAssignedTo;

  /// No description provided for @enquiryUnassigned.
  ///
  /// In hi, this message translates to:
  /// **'किसी को नहीं सौंपा गया'**
  String get enquiryUnassigned;

  /// No description provided for @enquiryReplyIn.
  ///
  /// In hi, this message translates to:
  /// **'उत्तर चाहिए'**
  String get enquiryReplyIn;

  /// No description provided for @enquiryReceivedOn.
  ///
  /// In hi, this message translates to:
  /// **'प्राप्त: {date}'**
  String enquiryReceivedOn(String date);

  /// No description provided for @enquiryResolvedOn.
  ///
  /// In hi, this message translates to:
  /// **'उत्तर दिया: {date}'**
  String enquiryResolvedOn(String date);

  /// No description provided for @enquiryOpenCount.
  ///
  /// In hi, this message translates to:
  /// **'{count} प्रतीक्षारत'**
  String enquiryOpenCount(int count);

  /// No description provided for @enquiryStatusUpdated.
  ///
  /// In hi, this message translates to:
  /// **'स्थिति बदल दी गई।'**
  String get enquiryStatusUpdated;

  /// No description provided for @enquiryAssignmentUpdated.
  ///
  /// In hi, this message translates to:
  /// **'जिम्मेदारी बदल दी गई।'**
  String get enquiryAssignmentUpdated;

  /// No description provided for @enquirySearchHint.
  ///
  /// In hi, this message translates to:
  /// **'संदर्भ, नाम, नंबर या संदेश खोजें'**
  String get enquirySearchHint;

  /// No description provided for @enquiryNoReplyChannel.
  ///
  /// In hi, this message translates to:
  /// **'कोई संपर्क विवरण नहीं दिया गया'**
  String get enquiryNoReplyChannel;

  /// No description provided for @enquirySpamNotice.
  ///
  /// In hi, this message translates to:
  /// **'स्पैम चिह्नित। यह सुरक्षित है, पर इनबॉक्स से हटा दिया गया है।'**
  String get enquirySpamNotice;

  /// No description provided for @enquiryPrivacyNotice.
  ///
  /// In hi, this message translates to:
  /// **'ये संदेश केवल समिति के लिए हैं।'**
  String get enquiryPrivacyNotice;

  /// No description provided for @errorEnquiryFormExpired.
  ///
  /// In hi, this message translates to:
  /// **'यह फ़ॉर्म समाप्त हो गया है। कृपया संदेश दोबारा भेजें।'**
  String get errorEnquiryFormExpired;

  /// No description provided for @errorEnquiryChallengeRequired.
  ///
  /// In hi, this message translates to:
  /// **'कृपया फ़ॉर्म के साथ दिया गया छोटा प्रश्न हल करें।'**
  String get errorEnquiryChallengeRequired;

  /// No description provided for @enquiryAssignToMe.
  ///
  /// In hi, this message translates to:
  /// **'मुझे सौंपें'**
  String get enquiryAssignToMe;

  /// No description provided for @enquiryUnassign.
  ///
  /// In hi, this message translates to:
  /// **'जिम्मेदारी हटाएं'**
  String get enquiryUnassign;

  /// No description provided for @enquiryChooseMember.
  ///
  /// In hi, this message translates to:
  /// **'किसी सदस्य को सौंपें'**
  String get enquiryChooseMember;

  /// No description provided for @navAnnouncements.
  ///
  /// In hi, this message translates to:
  /// **'सूचनाएं'**
  String get navAnnouncements;

  /// No description provided for @navAnnouncementsDesc.
  ///
  /// In hi, this message translates to:
  /// **'वेबसाइट की सूचनाएं, और उन्हें समिति को भेजना'**
  String get navAnnouncementsDesc;

  /// No description provided for @announcementsTitle.
  ///
  /// In hi, this message translates to:
  /// **'सूचनाएं'**
  String get announcementsTitle;

  /// No description provided for @announcementsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'वेबसाइट पर क्या दिख रहा है, क्या निर्धारित है, और क्या भेजा जा चुका है।'**
  String get announcementsSubtitle;

  /// No description provided for @announcementsEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी तक कोई सूचना नहीं।'**
  String get announcementsEmpty;

  /// No description provided for @announcementNew.
  ///
  /// In hi, this message translates to:
  /// **'नई सूचना लिखें'**
  String get announcementNew;

  /// No description provided for @announcementEdit.
  ///
  /// In hi, this message translates to:
  /// **'सूचना संपादित करें'**
  String get announcementEdit;

  /// No description provided for @announcementSaved.
  ///
  /// In hi, this message translates to:
  /// **'सूचना सहेजी गई।'**
  String get announcementSaved;

  /// No description provided for @announcementPublished.
  ///
  /// In hi, this message translates to:
  /// **'प्रकाशित। निर्धारित अवधि में यह वेबसाइट पर दिखेगी।'**
  String get announcementPublished;

  /// No description provided for @announcementArchived.
  ///
  /// In hi, this message translates to:
  /// **'संग्रहीत। वेबसाइट से हटा दी गई है, पर सुरक्षित है।'**
  String get announcementArchived;

  /// No description provided for @announcementStatusDraft.
  ///
  /// In hi, this message translates to:
  /// **'मसौदा'**
  String get announcementStatusDraft;

  /// No description provided for @announcementStatusPublished.
  ///
  /// In hi, this message translates to:
  /// **'प्रकाशित'**
  String get announcementStatusPublished;

  /// No description provided for @announcementStatusArchived.
  ///
  /// In hi, this message translates to:
  /// **'संग्रहीत'**
  String get announcementStatusArchived;

  /// No description provided for @announcementShowingNow.
  ///
  /// In hi, this message translates to:
  /// **'अभी वेबसाइट पर'**
  String get announcementShowingNow;

  /// No description provided for @announcementScheduledFor.
  ///
  /// In hi, this message translates to:
  /// **'आरंभ: {date}'**
  String announcementScheduledFor(String date);

  /// No description provided for @announcementExpiredOn.
  ///
  /// In hi, this message translates to:
  /// **'समाप्त: {date}'**
  String announcementExpiredOn(String date);

  /// No description provided for @announcementPriorityNormal.
  ///
  /// In hi, this message translates to:
  /// **'सामान्य'**
  String get announcementPriorityNormal;

  /// No description provided for @announcementPriorityImportant.
  ///
  /// In hi, this message translates to:
  /// **'महत्वपूर्ण'**
  String get announcementPriorityImportant;

  /// No description provided for @announcementPriorityUrgent.
  ///
  /// In hi, this message translates to:
  /// **'अत्यावश्यक'**
  String get announcementPriorityUrgent;

  /// No description provided for @fieldAnnouncementTitleHindi.
  ///
  /// In hi, this message translates to:
  /// **'शीर्षक (हिन्दी)'**
  String get fieldAnnouncementTitleHindi;

  /// No description provided for @fieldAnnouncementTitleEnglish.
  ///
  /// In hi, this message translates to:
  /// **'शीर्षक (अंग्रेज़ी)'**
  String get fieldAnnouncementTitleEnglish;

  /// No description provided for @fieldAnnouncementMessageHindi.
  ///
  /// In hi, this message translates to:
  /// **'संदेश (हिन्दी)'**
  String get fieldAnnouncementMessageHindi;

  /// No description provided for @fieldAnnouncementMessageEnglish.
  ///
  /// In hi, this message translates to:
  /// **'संदेश (अंग्रेज़ी)'**
  String get fieldAnnouncementMessageEnglish;

  /// No description provided for @fieldAnnouncementPriority.
  ///
  /// In hi, this message translates to:
  /// **'प्राथमिकता'**
  String get fieldAnnouncementPriority;

  /// No description provided for @fieldAnnouncementStart.
  ///
  /// In hi, this message translates to:
  /// **'कब से दिखे'**
  String get fieldAnnouncementStart;

  /// No description provided for @fieldAnnouncementEnd.
  ///
  /// In hi, this message translates to:
  /// **'कब तक दिखे'**
  String get fieldAnnouncementEnd;

  /// No description provided for @fieldAnnouncementEndHint.
  ///
  /// In hi, this message translates to:
  /// **'खाली छोड़ें तो संग्रहीत करने तक दिखती रहेगी'**
  String get fieldAnnouncementEndHint;

  /// No description provided for @fieldAnnouncementLink.
  ///
  /// In hi, this message translates to:
  /// **'अधिक जानकारी का लिंक'**
  String get fieldAnnouncementLink;

  /// No description provided for @actionPublish2.
  ///
  /// In hi, this message translates to:
  /// **'प्रकाशित करें'**
  String get actionPublish2;

  /// No description provided for @actionArchive.
  ///
  /// In hi, this message translates to:
  /// **'संग्रहीत करें'**
  String get actionArchive;

  /// No description provided for @announcementSend.
  ///
  /// In hi, this message translates to:
  /// **'यह सूचना भेजें'**
  String get announcementSend;

  /// No description provided for @announcementSendTitle.
  ///
  /// In hi, this message translates to:
  /// **'यह सूचना भेजें?'**
  String get announcementSendTitle;

  /// No description provided for @announcementSendBody.
  ///
  /// In hi, this message translates to:
  /// **'भेजने पर यह सूचना समिति के हर सक्रिय खाते के इनबॉक्स में पहुंचेगी। इसे वापस नहीं लिया जा सकता, और यह केवल एक बार भेजी जा सकती है।'**
  String get announcementSendBody;

  /// No description provided for @announcementSendConfirm.
  ///
  /// In hi, this message translates to:
  /// **'भेज दें'**
  String get announcementSendConfirm;

  /// No description provided for @announcementSent.
  ///
  /// In hi, this message translates to:
  /// **'{count} समिति सदस्यों को भेजी गई।'**
  String announcementSent(int count);

  /// No description provided for @announcementSentOn.
  ///
  /// In hi, this message translates to:
  /// **'भेजी गई: {date}'**
  String announcementSentOn(String date);

  /// No description provided for @announcementSentNotice.
  ///
  /// In hi, this message translates to:
  /// **'यह सूचना भेजी जा चुकी है और दोबारा नहीं भेजी जा सकती।'**
  String get announcementSentNotice;

  /// No description provided for @announcementChannels.
  ///
  /// In hi, this message translates to:
  /// **'किस माध्यम से भेजें'**
  String get announcementChannels;

  /// No description provided for @announcementChannelSite.
  ///
  /// In hi, this message translates to:
  /// **'केवल वेबसाइट'**
  String get announcementChannelSite;

  /// No description provided for @announcementChannelEmail.
  ///
  /// In hi, this message translates to:
  /// **'समिति को ईमेल'**
  String get announcementChannelEmail;

  /// No description provided for @announcementChannelSms.
  ///
  /// In hi, this message translates to:
  /// **'एसएमएस'**
  String get announcementChannelSms;

  /// No description provided for @announcementChannelWhatsapp.
  ///
  /// In hi, this message translates to:
  /// **'WhatsApp'**
  String get announcementChannelWhatsapp;

  /// No description provided for @announcementChannelUnavailable.
  ///
  /// In hi, this message translates to:
  /// **'किसी प्रदाता से जुड़ा नहीं है'**
  String get announcementChannelUnavailable;

  /// No description provided for @announcementRecipientsNote.
  ///
  /// In hi, this message translates to:
  /// **'ईमेल केवल समिति के खातों को जाता है। मंदिर को संदेश भेजने वाले भक्त किसी मेलिंग सूची में नहीं हैं।'**
  String get announcementRecipientsNote;

  /// No description provided for @announcementPublishBeforeSending.
  ///
  /// In hi, this message translates to:
  /// **'भेजने से पहले इस सूचना को प्रकाशित करें।'**
  String get announcementPublishBeforeSending;

  /// No description provided for @announcementSearchHint.
  ///
  /// In hi, this message translates to:
  /// **'शीर्षक या संदेश खोजें'**
  String get announcementSearchHint;

  /// No description provided for @announcementShowArchived.
  ///
  /// In hi, this message translates to:
  /// **'संग्रहीत भी दिखाएं'**
  String get announcementShowArchived;

  /// No description provided for @announcementBannerDismiss.
  ///
  /// In hi, this message translates to:
  /// **'यह सूचना बंद करें'**
  String get announcementBannerDismiss;

  /// No description provided for @errorAnnouncementAlreadySent.
  ///
  /// In hi, this message translates to:
  /// **'यह सूचना पहले ही भेजी जा चुकी है। दोबारा कहने के लिए नई सूचना लिखें।'**
  String get errorAnnouncementAlreadySent;

  /// No description provided for @errorAnnouncementNotPublished.
  ///
  /// In hi, this message translates to:
  /// **'भेजने से पहले इस सूचना को प्रकाशित करें।'**
  String get errorAnnouncementNotPublished;

  /// No description provided for @adminMenu.
  ///
  /// In hi, this message translates to:
  /// **'मेन्यू'**
  String get adminMenu;

  /// No description provided for @adminMenuOpen.
  ///
  /// In hi, this message translates to:
  /// **'मेन्यू खोलें'**
  String get adminMenuOpen;

  /// No description provided for @navAccounts.
  ///
  /// In hi, this message translates to:
  /// **'आय-व्यय'**
  String get navAccounts;

  /// No description provided for @navAccountsDesc.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर की आय और व्यय दर्ज करें, जाँचें और स्वीकृत करें'**
  String get navAccountsDesc;

  /// No description provided for @navAccountingCategories.
  ///
  /// In hi, this message translates to:
  /// **'आय-व्यय श्रेणियाँ'**
  String get navAccountingCategories;

  /// No description provided for @navAccountingCategoriesDesc.
  ///
  /// In hi, this message translates to:
  /// **'किस मद में आय या व्यय दर्ज होगा, वे शीर्षक'**
  String get navAccountingCategoriesDesc;

  /// No description provided for @navAccountingSettings.
  ///
  /// In hi, this message translates to:
  /// **'लेखा सेटिंग्स'**
  String get navAccountingSettings;

  /// No description provided for @navAccountingSettingsDesc.
  ///
  /// In hi, this message translates to:
  /// **'आरंभिक शेष, और लेखा-जोखा वेबसाइट पर दिखाना'**
  String get navAccountingSettingsDesc;

  /// No description provided for @navTransparency.
  ///
  /// In hi, this message translates to:
  /// **'आय-व्यय'**
  String get navTransparency;

  /// No description provided for @transparencyTitle.
  ///
  /// In hi, this message translates to:
  /// **'आय-व्यय का लेखा-जोखा'**
  String get transparencyTitle;

  /// No description provided for @transparencySubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर को क्या प्राप्त हुआ और कहाँ व्यय हुआ'**
  String get transparencySubtitle;

  /// No description provided for @transparencyNotPublishedTitle.
  ///
  /// In hi, this message translates to:
  /// **'लेखा-जोखा अभी प्रकाशित नहीं है'**
  String get transparencyNotPublishedTitle;

  /// No description provided for @transparencyNotPublishedBody.
  ///
  /// In hi, this message translates to:
  /// **'समिति ने अभी मंदिर का आय-व्यय विवरण वेबसाइट पर प्रकाशित नहीं किया है। अधिक जानकारी के लिए कृपया समिति से संपर्क करें।'**
  String get transparencyNotPublishedBody;

  /// No description provided for @transparencySelectYear.
  ///
  /// In hi, this message translates to:
  /// **'वित्तीय वर्ष चुनें'**
  String get transparencySelectYear;

  /// No description provided for @transparencyYearHeading.
  ///
  /// In hi, this message translates to:
  /// **'वित्तीय वर्ष {label}'**
  String transparencyYearHeading(String label);

  /// No description provided for @transparencyOpeningBalance.
  ///
  /// In hi, this message translates to:
  /// **'वर्ष के आरंभ में शेष'**
  String get transparencyOpeningBalance;

  /// No description provided for @transparencyDonations.
  ///
  /// In hi, this message translates to:
  /// **'दान से प्राप्त'**
  String get transparencyDonations;

  /// No description provided for @transparencyOtherIncome.
  ///
  /// In hi, this message translates to:
  /// **'अन्य आय'**
  String get transparencyOtherIncome;

  /// No description provided for @transparencyTotalIncome.
  ///
  /// In hi, this message translates to:
  /// **'कुल आय'**
  String get transparencyTotalIncome;

  /// No description provided for @transparencyTotalExpense.
  ///
  /// In hi, this message translates to:
  /// **'कुल व्यय'**
  String get transparencyTotalExpense;

  /// No description provided for @transparencyClosingBalance.
  ///
  /// In hi, this message translates to:
  /// **'वर्ष के अंत में शेष'**
  String get transparencyClosingBalance;

  /// No description provided for @transparencyIncomeBreakdown.
  ///
  /// In hi, this message translates to:
  /// **'आय का विवरण'**
  String get transparencyIncomeBreakdown;

  /// No description provided for @transparencyExpenseBreakdown.
  ///
  /// In hi, this message translates to:
  /// **'व्यय का विवरण'**
  String get transparencyExpenseBreakdown;

  /// No description provided for @transparencyDonationCount.
  ///
  /// In hi, this message translates to:
  /// **'{count, plural, =0{इस वर्ष कोई दान दर्ज नहीं} =1{1 दान} other{{count} दान}}'**
  String transparencyDonationCount(int count);

  /// No description provided for @transparencyNoIncome.
  ///
  /// In hi, this message translates to:
  /// **'इस वर्ष दान के अतिरिक्त कोई आय दर्ज नहीं है।'**
  String get transparencyNoIncome;

  /// No description provided for @transparencyNoExpense.
  ///
  /// In hi, this message translates to:
  /// **'इस वर्ष कोई व्यय दर्ज नहीं है।'**
  String get transparencyNoExpense;

  /// No description provided for @transparencyEmptyYear.
  ///
  /// In hi, this message translates to:
  /// **'इस वित्तीय वर्ष का कोई लेखा अभी दर्ज नहीं हुआ है।'**
  String get transparencyEmptyYear;

  /// No description provided for @transparencyOnlyApprovedNote.
  ///
  /// In hi, this message translates to:
  /// **'इन आँकड़ों में केवल वे प्रविष्टियाँ सम्मिलित हैं जिन्हें समिति ने बिल या बैंक विवरण से मिलान कर स्वीकृत किया है।'**
  String get transparencyOnlyApprovedNote;

  /// No description provided for @transparencyNoNamesNote.
  ///
  /// In hi, this message translates to:
  /// **'यहाँ किसी दानदाता या विक्रेता का नाम प्रकाशित नहीं किया जाता — केवल कुल राशि और मद।'**
  String get transparencyNoNamesNote;

  /// No description provided for @transparencyAsOf.
  ///
  /// In hi, this message translates to:
  /// **'{date} तक'**
  String transparencyAsOf(String date);

  /// No description provided for @transparencyOpeningBalanceOn.
  ///
  /// In hi, this message translates to:
  /// **'{date} से'**
  String transparencyOpeningBalanceOn(String date);

  /// No description provided for @accountsTitle.
  ///
  /// In hi, this message translates to:
  /// **'आय-व्यय'**
  String get accountsTitle;

  /// No description provided for @accountsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर की बही'**
  String get accountsSubtitle;

  /// No description provided for @accountsNewEntry.
  ///
  /// In hi, this message translates to:
  /// **'नई प्रविष्टि'**
  String get accountsNewEntry;

  /// No description provided for @accountsEditEntry.
  ///
  /// In hi, this message translates to:
  /// **'प्रविष्टि संपादित करें'**
  String get accountsEditEntry;

  /// No description provided for @accountsTypeIncome.
  ///
  /// In hi, this message translates to:
  /// **'आय'**
  String get accountsTypeIncome;

  /// No description provided for @accountsTypeExpense.
  ///
  /// In hi, this message translates to:
  /// **'व्यय'**
  String get accountsTypeExpense;

  /// No description provided for @accountsStatusPending.
  ///
  /// In hi, this message translates to:
  /// **'जाँच शेष'**
  String get accountsStatusPending;

  /// No description provided for @accountsStatusApproved.
  ///
  /// In hi, this message translates to:
  /// **'स्वीकृत'**
  String get accountsStatusApproved;

  /// No description provided for @accountsStatusReversed.
  ///
  /// In hi, this message translates to:
  /// **'निरस्त'**
  String get accountsStatusReversed;

  /// No description provided for @accountsAllTypes.
  ///
  /// In hi, this message translates to:
  /// **'सभी'**
  String get accountsAllTypes;

  /// No description provided for @accountsAllStatuses.
  ///
  /// In hi, this message translates to:
  /// **'सभी स्थितियाँ'**
  String get accountsAllStatuses;

  /// No description provided for @accountsAllCategories.
  ///
  /// In hi, this message translates to:
  /// **'सभी श्रेणियाँ'**
  String get accountsAllCategories;

  /// No description provided for @accountsApprovedIncome.
  ///
  /// In hi, this message translates to:
  /// **'स्वीकृत आय'**
  String get accountsApprovedIncome;

  /// No description provided for @accountsApprovedExpense.
  ///
  /// In hi, this message translates to:
  /// **'स्वीकृत व्यय'**
  String get accountsApprovedExpense;

  /// No description provided for @accountsNet.
  ///
  /// In hi, this message translates to:
  /// **'बही का शुद्ध'**
  String get accountsNet;

  /// No description provided for @accountsPendingNotCounted.
  ///
  /// In hi, this message translates to:
  /// **'{count, plural, =1{1 प्रविष्टि की जाँच शेष है और वह किसी योग में नहीं गिनी गई} other{{count} प्रविष्टियों की जाँच शेष है और वे किसी योग में नहीं गिनी गईं}}'**
  String accountsPendingNotCounted(int count);

  /// No description provided for @accountsEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई प्रविष्टि नहीं है।'**
  String get accountsEmpty;

  /// No description provided for @accountsEmptyFiltered.
  ///
  /// In hi, this message translates to:
  /// **'इस छाँट के अनुसार कोई प्रविष्टि नहीं मिली।'**
  String get accountsEmptyFiltered;

  /// No description provided for @accountsSearchHint.
  ///
  /// In hi, this message translates to:
  /// **'किसे भुगतान, विवरण या संदर्भ खोजें'**
  String get accountsSearchHint;

  /// No description provided for @accountsFieldCategory.
  ///
  /// In hi, this message translates to:
  /// **'श्रेणी'**
  String get accountsFieldCategory;

  /// No description provided for @accountsFieldAmount.
  ///
  /// In hi, this message translates to:
  /// **'राशि'**
  String get accountsFieldAmount;

  /// No description provided for @accountsFieldDate.
  ///
  /// In hi, this message translates to:
  /// **'तिथि'**
  String get accountsFieldDate;

  /// No description provided for @accountsFieldPaymentMode.
  ///
  /// In hi, this message translates to:
  /// **'भुगतान का माध्यम'**
  String get accountsFieldPaymentMode;

  /// No description provided for @accountsFieldReference.
  ///
  /// In hi, this message translates to:
  /// **'संदर्भ संख्या'**
  String get accountsFieldReference;

  /// No description provided for @accountsFieldPayee.
  ///
  /// In hi, this message translates to:
  /// **'किसे भुगतान / किससे प्राप्त'**
  String get accountsFieldPayee;

  /// No description provided for @accountsFieldDescription.
  ///
  /// In hi, this message translates to:
  /// **'विवरण'**
  String get accountsFieldDescription;

  /// No description provided for @accountsPayeeHelp.
  ///
  /// In hi, this message translates to:
  /// **'यह नाम वेबसाइट पर कभी प्रकाशित नहीं होता।'**
  String get accountsPayeeHelp;

  /// No description provided for @accountsDescriptionHelp.
  ///
  /// In hi, this message translates to:
  /// **'बही के लिए आपका अपना नोट। यह भी प्रकाशित नहीं होता।'**
  String get accountsDescriptionHelp;

  /// No description provided for @accountsBill.
  ///
  /// In hi, this message translates to:
  /// **'बिल / रसीद'**
  String get accountsBill;

  /// No description provided for @accountsAttachBill.
  ///
  /// In hi, this message translates to:
  /// **'बिल संलग्न करें'**
  String get accountsAttachBill;

  /// No description provided for @accountsReplaceBill.
  ///
  /// In hi, this message translates to:
  /// **'बिल बदलें'**
  String get accountsReplaceBill;

  /// No description provided for @accountsViewBill.
  ///
  /// In hi, this message translates to:
  /// **'बिल देखें'**
  String get accountsViewBill;

  /// No description provided for @accountsNoBill.
  ///
  /// In hi, this message translates to:
  /// **'कोई बिल संलग्न नहीं है'**
  String get accountsNoBill;

  /// No description provided for @accountsBillHelp.
  ///
  /// In hi, this message translates to:
  /// **'फोटो या PDF। बिल केवल समिति के सदस्य देख सकते हैं, वेबसाइट पर कभी नहीं दिखता।'**
  String get accountsBillHelp;

  /// No description provided for @accountsBillLocked.
  ///
  /// In hi, this message translates to:
  /// **'स्वीकृत प्रविष्टि का बिल नहीं बदला जा सकता।'**
  String get accountsBillLocked;

  /// No description provided for @accountsApprove.
  ///
  /// In hi, this message translates to:
  /// **'स्वीकृत करें'**
  String get accountsApprove;

  /// No description provided for @accountsApproveTitle.
  ///
  /// In hi, this message translates to:
  /// **'यह प्रविष्टि स्वीकृत करें?'**
  String get accountsApproveTitle;

  /// No description provided for @accountsApproveBody.
  ///
  /// In hi, this message translates to:
  /// **'स्वीकृति के बाद यह राशि हर योग में गिनी जाएगी — उस पृष्ठ पर भी जो गाँव पढ़ता है — और तब विवरण के अतिरिक्त कुछ भी नहीं बदला जा सकेगा। सुधार का एकमात्र उपाय निरस्त कर दोबारा दर्ज करना है।'**
  String get accountsApproveBody;

  /// No description provided for @accountsReverse.
  ///
  /// In hi, this message translates to:
  /// **'निरस्त करें'**
  String get accountsReverse;

  /// No description provided for @accountsReverseTitle.
  ///
  /// In hi, this message translates to:
  /// **'यह प्रविष्टि निरस्त करें?'**
  String get accountsReverseTitle;

  /// No description provided for @accountsReverseBody.
  ///
  /// In hi, this message translates to:
  /// **'पंक्ति बही में बनी रहेगी, बिल सहित, और किसी योग में नहीं गिनी जाएगी। कारण लिखना आवश्यक है — महीनों बाद यही बताएगा कि यह राशि क्यों हटाई गई।'**
  String get accountsReverseBody;

  /// No description provided for @accountsReverseReason.
  ///
  /// In hi, this message translates to:
  /// **'निरस्त करने का कारण'**
  String get accountsReverseReason;

  /// No description provided for @accountsReversedOn.
  ///
  /// In hi, this message translates to:
  /// **'{date} को निरस्त'**
  String accountsReversedOn(String date);

  /// No description provided for @accountsApprovedOn.
  ///
  /// In hi, this message translates to:
  /// **'{date} को स्वीकृत'**
  String accountsApprovedOn(String date);

  /// No description provided for @accountsRecordedBy.
  ///
  /// In hi, this message translates to:
  /// **'दर्ज किया: {name}'**
  String accountsRecordedBy(String name);

  /// No description provided for @accountsApprovedBy.
  ///
  /// In hi, this message translates to:
  /// **'स्वीकृत किया: {name}'**
  String accountsApprovedBy(String name);

  /// No description provided for @accountsReversedBy.
  ///
  /// In hi, this message translates to:
  /// **'निरस्त किया: {name}'**
  String accountsReversedBy(String name);

  /// No description provided for @accountsLockedNotice.
  ///
  /// In hi, this message translates to:
  /// **'यह प्रविष्टि स्वीकृत हो चुकी है और प्रकाशित योगों में गिनी जा चुकी है, इसलिए विवरण के अतिरिक्त कुछ नहीं बदला जा सकता। सुधार के लिए इसे निरस्त कर दोबारा दर्ज करें।'**
  String get accountsLockedNotice;

  /// No description provided for @accountsPendingNotice.
  ///
  /// In hi, this message translates to:
  /// **'यह प्रविष्टि अभी किसी योग में नहीं गिनी गई है। बिल या बैंक विवरण से मिलान करने के बाद इसे स्वीकृत करें।'**
  String get accountsPendingNotice;

  /// No description provided for @accountsDonationsElsewhere.
  ///
  /// In hi, this message translates to:
  /// **'दान यहाँ दर्ज नहीं होते। वे दान रजिस्टर में दर्ज होते हैं और वहीं से गिने जाते हैं।'**
  String get accountsDonationsElsewhere;

  /// No description provided for @accountsCategoriesTitle.
  ///
  /// In hi, this message translates to:
  /// **'आय-व्यय श्रेणियाँ'**
  String get accountsCategoriesTitle;

  /// No description provided for @accountsCategoriesSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'वे शीर्षक जिनके अंतर्गत बही की हर प्रविष्टि आती है'**
  String get accountsCategoriesSubtitle;

  /// No description provided for @accountsCategoryNew.
  ///
  /// In hi, this message translates to:
  /// **'नई श्रेणी'**
  String get accountsCategoryNew;

  /// No description provided for @accountsCategoryEdit.
  ///
  /// In hi, this message translates to:
  /// **'श्रेणी संपादित करें'**
  String get accountsCategoryEdit;

  /// No description provided for @accountsCategoryNameHi.
  ///
  /// In hi, this message translates to:
  /// **'नाम (हिन्दी)'**
  String get accountsCategoryNameHi;

  /// No description provided for @accountsCategoryNameEn.
  ///
  /// In hi, this message translates to:
  /// **'नाम (अंग्रेज़ी)'**
  String get accountsCategoryNameEn;

  /// No description provided for @accountsCategoryActive.
  ///
  /// In hi, this message translates to:
  /// **'प्रयोग में'**
  String get accountsCategoryActive;

  /// No description provided for @accountsCategoryInactive.
  ///
  /// In hi, this message translates to:
  /// **'बंद'**
  String get accountsCategoryInactive;

  /// No description provided for @accountsCategoryUsage.
  ///
  /// In hi, this message translates to:
  /// **'{count, plural, =0{किसी प्रविष्टि में प्रयुक्त नहीं} =1{1 प्रविष्टि में} other{{count} प्रविष्टियों में}}'**
  String accountsCategoryUsage(int count);

  /// No description provided for @accountsCategoryDelete.
  ///
  /// In hi, this message translates to:
  /// **'हटाएँ'**
  String get accountsCategoryDelete;

  /// No description provided for @accountsCategoryDeleteTitle.
  ///
  /// In hi, this message translates to:
  /// **'यह श्रेणी हटाएँ?'**
  String get accountsCategoryDeleteTitle;

  /// No description provided for @accountsCategoryDeleteBody.
  ///
  /// In hi, this message translates to:
  /// **'इस शीर्षक के अंतर्गत कोई प्रविष्टि नहीं है, इसलिए इसे हटाया जा सकता है।'**
  String get accountsCategoryDeleteBody;

  /// No description provided for @accountsCategoryDeactivate.
  ///
  /// In hi, this message translates to:
  /// **'बंद करें'**
  String get accountsCategoryDeactivate;

  /// No description provided for @accountsCategoryReactivate.
  ///
  /// In hi, this message translates to:
  /// **'फिर से चालू करें'**
  String get accountsCategoryReactivate;

  /// No description provided for @accountsCategoryInUseNotice.
  ///
  /// In hi, this message translates to:
  /// **'इस शीर्षक के अंतर्गत प्रविष्टियाँ दर्ज हैं, इसलिए इसे न हटाया जा सकता है और न आय से व्यय में बदला जा सकता है — दोनों से पुरानी प्रविष्टियों का अर्थ बदल जाएगा। इसे बंद कर दें: नई प्रविष्टियों में यह नहीं दिखेगा और पुरानी वैसी ही पढ़ी जाएँगी।'**
  String get accountsCategoryInUseNotice;

  /// No description provided for @accountsCategoryEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई श्रेणी नहीं है।'**
  String get accountsCategoryEmpty;

  /// No description provided for @accountsSettingsTitle.
  ///
  /// In hi, this message translates to:
  /// **'लेखा सेटिंग्स'**
  String get accountsSettingsTitle;

  /// No description provided for @accountsSettingsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'आरंभिक शेष, और लेखा-जोखा सार्वजनिक करना'**
  String get accountsSettingsSubtitle;

  /// No description provided for @accountsPublishBooks.
  ///
  /// In hi, this message translates to:
  /// **'आय-व्यय वेबसाइट पर दिखाएँ'**
  String get accountsPublishBooks;

  /// No description provided for @accountsPublishBooksHelp.
  ///
  /// In hi, this message translates to:
  /// **'चालू करने पर मंदिर की वेबसाइट पर वर्ष का कुल आय, कुल व्यय और मदवार विवरण दिखने लगेगा। किसी दानदाता या विक्रेता का नाम कभी नहीं दिखता। जब तक यह बंद है, वेबसाइट पर कोई आँकड़ा नहीं दिखता।'**
  String get accountsPublishBooksHelp;

  /// No description provided for @accountsBooksArePublic.
  ///
  /// In hi, this message translates to:
  /// **'लेखा-जोखा वेबसाइट पर दिख रहा है'**
  String get accountsBooksArePublic;

  /// No description provided for @accountsBooksAreNotPublic.
  ///
  /// In hi, this message translates to:
  /// **'लेखा-जोखा अभी वेबसाइट पर नहीं दिख रहा'**
  String get accountsBooksAreNotPublic;

  /// No description provided for @accountsOpeningBalance.
  ///
  /// In hi, this message translates to:
  /// **'आरंभिक शेष'**
  String get accountsOpeningBalance;

  /// No description provided for @accountsOpeningBalanceHelp.
  ///
  /// In hi, this message translates to:
  /// **'इस सॉफ़्टवेयर में लेखा आरंभ करते समय मंदिर के पास जो राशि थी। इसके बिना प्रकाशित शेष उतना ही कम दिखेगा। घाटे में आरंभ हो तो ऋणात्मक राशि लिखें।'**
  String get accountsOpeningBalanceHelp;

  /// No description provided for @accountsOpeningBalanceDate.
  ///
  /// In hi, this message translates to:
  /// **'आरंभिक शेष की तिथि'**
  String get accountsOpeningBalanceDate;

  /// No description provided for @accountsIntroHi.
  ///
  /// In hi, this message translates to:
  /// **'परिचय (हिन्दी)'**
  String get accountsIntroHi;

  /// No description provided for @accountsIntroEn.
  ///
  /// In hi, this message translates to:
  /// **'परिचय (अंग्रेज़ी)'**
  String get accountsIntroEn;

  /// No description provided for @accountsNoteHi.
  ///
  /// In hi, this message translates to:
  /// **'टिप्पणी (हिन्दी)'**
  String get accountsNoteHi;

  /// No description provided for @accountsNoteEn.
  ///
  /// In hi, this message translates to:
  /// **'टिप्पणी (अंग्रेज़ी)'**
  String get accountsNoteEn;

  /// No description provided for @accountsIntroHelp.
  ///
  /// In hi, this message translates to:
  /// **'यह वाक्य आय-व्यय पृष्ठ के आरंभ में दिखेगा।'**
  String get accountsIntroHelp;

  /// No description provided for @errorTransactionLocked.
  ///
  /// In hi, this message translates to:
  /// **'यह प्रविष्टि स्वीकृत या निरस्त हो चुकी है, इसलिए यह कार्य अब संभव नहीं है।'**
  String get errorTransactionLocked;

  /// No description provided for @errorAccountsNotPublished.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर ने अभी अपना लेखा-जोखा प्रकाशित नहीं किया है।'**
  String get errorAccountsNotPublished;

  /// No description provided for @navReports.
  ///
  /// In hi, this message translates to:
  /// **'रिपोर्ट'**
  String get navReports;

  /// No description provided for @navReportsDesc.
  ///
  /// In hi, this message translates to:
  /// **'दान, बही, कार्यक्रम एवं पूछताछ की मानक रिपोर्ट'**
  String get navReportsDesc;

  /// No description provided for @reportsTitle.
  ///
  /// In hi, this message translates to:
  /// **'रिपोर्ट'**
  String get reportsTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर के अभिलेखों की मानक रिपोर्ट, और उनकी प्रति'**
  String get reportsSubtitle;

  /// No description provided for @reportsEmpty.
  ///
  /// In hi, this message translates to:
  /// **'इस खाते के लिए कोई रिपोर्ट उपलब्ध नहीं है।'**
  String get reportsEmpty;

  /// No description provided for @reportOpen.
  ///
  /// In hi, this message translates to:
  /// **'खोलें'**
  String get reportOpen;

  /// No description provided for @reportHasPersonal.
  ///
  /// In hi, this message translates to:
  /// **'इसमें व्यक्तिगत विवरण के स्तंभ हैं'**
  String get reportHasPersonal;

  /// No description provided for @reportFilterPeriod.
  ///
  /// In hi, this message translates to:
  /// **'अवधि'**
  String get reportFilterPeriod;

  /// No description provided for @reportFilterYear.
  ///
  /// In hi, this message translates to:
  /// **'वित्तीय वर्ष'**
  String get reportFilterYear;

  /// No description provided for @reportFilterFrom.
  ///
  /// In hi, this message translates to:
  /// **'से'**
  String get reportFilterFrom;

  /// No description provided for @reportFilterTo.
  ///
  /// In hi, this message translates to:
  /// **'तक'**
  String get reportFilterTo;

  /// No description provided for @reportFilterApply.
  ///
  /// In hi, this message translates to:
  /// **'लागू करें'**
  String get reportFilterApply;

  /// No description provided for @reportFilterClear.
  ///
  /// In hi, this message translates to:
  /// **'छाँट हटाएँ'**
  String get reportFilterClear;

  /// No description provided for @reportFiltersApplied.
  ///
  /// In hi, this message translates to:
  /// **'लागू छाँट: {filters}'**
  String reportFiltersApplied(String filters);

  /// No description provided for @reportRowCount.
  ///
  /// In hi, this message translates to:
  /// **'{count, plural, =0{कोई पंक्ति नहीं} =1{1 पंक्ति} other{{count} पंक्तियाँ}}'**
  String reportRowCount(int count);

  /// No description provided for @reportEmpty.
  ///
  /// In hi, this message translates to:
  /// **'इस छाँट के अनुसार कोई प्रविष्टि नहीं मिली।'**
  String get reportEmpty;

  /// No description provided for @reportIncludePersonal.
  ///
  /// In hi, this message translates to:
  /// **'व्यक्तिगत विवरण सम्मिलित करें'**
  String get reportIncludePersonal;

  /// No description provided for @reportIncludePersonalHelp.
  ///
  /// In hi, this message translates to:
  /// **'नाम, दूरभाष और पता। बंद रहने पर ये स्तंभ प्रतिक्रिया में होते ही नहीं — छिपाए नहीं जाते। फ़ाइल में इसका उल्लेख भी होता है।'**
  String get reportIncludePersonalHelp;

  /// No description provided for @reportPersonalIncluded.
  ///
  /// In hi, this message translates to:
  /// **'इस दृश्य में व्यक्तिगत विवरण सम्मिलित हैं'**
  String get reportPersonalIncluded;

  /// No description provided for @reportExport.
  ///
  /// In hi, this message translates to:
  /// **'प्रति लें'**
  String get reportExport;

  /// No description provided for @reportExportCsv.
  ///
  /// In hi, this message translates to:
  /// **'CSV'**
  String get reportExportCsv;

  /// No description provided for @reportExportXlsx.
  ///
  /// In hi, this message translates to:
  /// **'Excel'**
  String get reportExportXlsx;

  /// No description provided for @reportExportPdf.
  ///
  /// In hi, this message translates to:
  /// **'प्रिंट / PDF'**
  String get reportExportPdf;

  /// No description provided for @reportExportNote.
  ///
  /// In hi, this message translates to:
  /// **'फ़ाइल में वही पंक्तियाँ आती हैं जो यहाँ दिख रही हैं — वही छाँट, वही अवधि।'**
  String get reportExportNote;

  /// No description provided for @reportExportForbidden.
  ///
  /// In hi, this message translates to:
  /// **'इस खाते को रिपोर्ट की प्रति लेने की अनुमति नहीं है।'**
  String get reportExportForbidden;

  /// No description provided for @reportExportLimit.
  ///
  /// In hi, this message translates to:
  /// **'एक फ़ाइल में अधिकतम {count} पंक्तियाँ आती हैं। इससे अधिक होने पर छोटी अवधि चुनें।'**
  String reportExportLimit(int count);

  /// No description provided for @overviewTitle.
  ///
  /// In hi, this message translates to:
  /// **'एक नज़र में'**
  String get overviewTitle;

  /// No description provided for @overviewYear.
  ///
  /// In hi, this message translates to:
  /// **'वित्तीय वर्ष {label}'**
  String overviewYear(String label);

  /// No description provided for @overviewDonations.
  ///
  /// In hi, this message translates to:
  /// **'दान से प्राप्त'**
  String get overviewDonations;

  /// No description provided for @overviewIncome.
  ///
  /// In hi, this message translates to:
  /// **'कुल आय'**
  String get overviewIncome;

  /// No description provided for @overviewExpense.
  ///
  /// In hi, this message translates to:
  /// **'कुल व्यय'**
  String get overviewExpense;

  /// No description provided for @overviewBalance.
  ///
  /// In hi, this message translates to:
  /// **'वर्तमान शेष'**
  String get overviewBalance;

  /// No description provided for @overviewDonationCount.
  ///
  /// In hi, this message translates to:
  /// **'{count, plural, =0{कोई दान नहीं} =1{1 दान} other{{count} दान}}'**
  String overviewDonationCount(int count);

  /// No description provided for @overviewTrend.
  ///
  /// In hi, this message translates to:
  /// **'पिछले 12 माह में दान'**
  String get overviewTrend;

  /// No description provided for @overviewTrendEmpty.
  ///
  /// In hi, this message translates to:
  /// **'पिछले बारह माह में कोई दान दर्ज नहीं है।'**
  String get overviewTrendEmpty;

  /// No description provided for @overviewEnquiries.
  ///
  /// In hi, this message translates to:
  /// **'लंबित पूछताछ'**
  String get overviewEnquiries;

  /// No description provided for @overviewEnquiriesNew.
  ///
  /// In hi, this message translates to:
  /// **'{count, plural, =0{कोई नया संदेश नहीं} =1{1 नया संदेश} other{{count} नए संदेश}}'**
  String overviewEnquiriesNew(int count);

  /// No description provided for @overviewUpcoming.
  ///
  /// In hi, this message translates to:
  /// **'आगामी कार्यक्रम'**
  String get overviewUpcoming;

  /// No description provided for @overviewUpcomingEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अगले तीस दिनों में कोई कार्यक्रम नहीं है।'**
  String get overviewUpcomingEmpty;

  /// No description provided for @overviewEventCancelled.
  ///
  /// In hi, this message translates to:
  /// **'रद्द'**
  String get overviewEventCancelled;

  /// No description provided for @overviewOpenReports.
  ///
  /// In hi, this message translates to:
  /// **'सभी रिपोर्ट देखें'**
  String get overviewOpenReports;

  /// No description provided for @errorReportDisclosureRefused.
  ///
  /// In hi, this message translates to:
  /// **'यह रिपोर्ट देखी जा सकती है, पर व्यक्तिगत विवरण के लिए अनुमति चाहिए जो इस खाते के पास नहीं है।'**
  String get errorReportDisclosureRefused;

  /// No description provided for @errorReportTooLarge.
  ///
  /// In hi, this message translates to:
  /// **'यह अवधि एक फ़ाइल के लिए बहुत बड़ी है। छोटी अवधि चुनकर भागों में प्रति लें।'**
  String get errorReportTooLarge;

  /// No description provided for @sectionContactLocation.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क एवं स्थान'**
  String get sectionContactLocation;

  /// No description provided for @sectionContactLocationSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर तक पहुँचने या समिति से संपर्क करने के लिए नीचे दी गई जानकारी का उपयोग करें।'**
  String get sectionContactLocationSubtitle;

  /// No description provided for @sectionEventsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर के प्रमुख धार्मिक और सामुदायिक कार्यक्रमों की जानकारी।'**
  String get sectionEventsSubtitle;

  /// No description provided for @homeAccountsTitle.
  ///
  /// In hi, this message translates to:
  /// **'आय-व्यय पारदर्शिता'**
  String get homeAccountsTitle;

  /// No description provided for @homeAccountsSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'इस वित्तीय वर्ष में मंदिर को क्या प्राप्त हुआ और कहाँ व्यय हुआ।'**
  String get homeAccountsSubtitle;

  /// No description provided for @statDonationsReceived.
  ///
  /// In hi, this message translates to:
  /// **'कुल प्राप्त दान'**
  String get statDonationsReceived;

  /// No description provided for @statTotalExpense.
  ///
  /// In hi, this message translates to:
  /// **'कुल व्यय'**
  String get statTotalExpense;

  /// No description provided for @statAvailableBalance.
  ///
  /// In hi, this message translates to:
  /// **'उपलब्ध शेष'**
  String get statAvailableBalance;

  /// No description provided for @statDonors.
  ///
  /// In hi, this message translates to:
  /// **'दानदाता'**
  String get statDonors;

  /// No description provided for @viewTransparency.
  ///
  /// In hi, this message translates to:
  /// **'पूरा लेखा-जोखा देखें'**
  String get viewTransparency;

  /// No description provided for @addressVillageLabel.
  ///
  /// In hi, this message translates to:
  /// **'ग्राम'**
  String get addressVillageLabel;

  /// No description provided for @addressPoliceStationLabel.
  ///
  /// In hi, this message translates to:
  /// **'थाना'**
  String get addressPoliceStationLabel;

  /// No description provided for @addressDistrictLabel.
  ///
  /// In hi, this message translates to:
  /// **'जिला'**
  String get addressDistrictLabel;

  /// No description provided for @footerQuickLinks.
  ///
  /// In hi, this message translates to:
  /// **'त्वरित लिंक'**
  String get footerQuickLinks;

  /// Footer copyright line. {temple} is the temple name and its locality.
  ///
  /// In hi, this message translates to:
  /// **'© {year} {temple}। सर्वाधिकार सुरक्षित।'**
  String footerCopyright(String year, String temple);

  /// No description provided for @eventFeatured.
  ///
  /// In hi, this message translates to:
  /// **'विशेष'**
  String get eventFeatured;

  /// No description provided for @eventTypeCommunityService.
  ///
  /// In hi, this message translates to:
  /// **'सामुदायिक सेवा'**
  String get eventTypeCommunityService;

  /// No description provided for @pageCardsHint.
  ///
  /// In hi, this message translates to:
  /// **'किसी अनुच्छेद को “🛕 शीर्षक — विवरण” के रूप में लिखें तो वह वेबसाइट पर अलग कार्ड की तरह दिखेगा।'**
  String get pageCardsHint;

  /// No description provided for @footerContact.
  ///
  /// In hi, this message translates to:
  /// **'संपर्क'**
  String get footerContact;
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
