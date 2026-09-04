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
  /// **'राधे राधे · जय श्री कृष्ण'**
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
