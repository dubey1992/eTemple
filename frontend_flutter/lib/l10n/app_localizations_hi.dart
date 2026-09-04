// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'राधा कृष्ण ठाकुरबाड़ी';

  @override
  String get appSubtitle => 'अमरपुर पंखोरिया, कुर्मा पंचायत';

  @override
  String get invocation => '॥ राधे कृष्ण ॥';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageEnglish => 'English';

  @override
  String get switchToEnglish => 'अंग्रेज़ी में देखें';

  @override
  String get switchToHindi => 'हिन्दी में देखें';

  @override
  String get navHome => 'मुख पृष्ठ';

  @override
  String get navAdmin => 'प्रबंधन';

  @override
  String get signIn => 'साइन इन';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get foundationHeadline => 'वेबसाइट तैयार की जा रही है';

  @override
  String get foundationBody =>
      'मंदिर की जानकारी, कार्यक्रम, चित्र और दान विवरण शीघ्र ही यहाँ उपलब्ध होंगे।';

  @override
  String get foundationNote =>
      'यह पृष्ठ केवल तकनीकी आधार दर्शाता है। सामग्री अगले चरण में जोड़ी जाएगी।';

  @override
  String get loginTitle => 'प्रबंधन लॉगिन';

  @override
  String get loginSubtitle => 'केवल समिति सदस्यों के लिए';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get rememberMe => 'मुझे याद रखें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get forgotPasswordTitle => 'पासवर्ड रीसेट करें';

  @override
  String get forgotPasswordSubtitle =>
      'अपना पंजीकृत ईमेल दर्ज करें। यदि खाता सक्रिय है तो रीसेट लिंक भेजा जाएगा।';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get backToLogin => 'लॉगिन पर वापस जाएँ';

  @override
  String get adminDashboardTitle => 'प्रबंधन डैशबोर्ड';

  @override
  String adminWelcome(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get adminFoundationNote =>
      'प्रबंधन सुविधाएँ अगले चरणों में जोड़ी जाएँगी।';

  @override
  String get roleLabel => 'भूमिका';

  @override
  String get validationRequired => 'यह जानकारी आवश्यक है';

  @override
  String get validationEmailInvalid => 'कृपया वैध ईमेल पता दर्ज करें';

  @override
  String validationPasswordTooShort(int count) {
    return 'पासवर्ड कम से कम $count अक्षरों का होना चाहिए';
  }

  @override
  String get stateLoading => 'लोड हो रहा है…';

  @override
  String get stateEmpty => 'अभी कोई जानकारी उपलब्ध नहीं है';

  @override
  String get stateRetry => 'पुनः प्रयास करें';

  @override
  String get stateUnauthorizedTitle => 'अनुमति नहीं है';

  @override
  String get stateUnauthorizedBody =>
      'इस पृष्ठ को देखने के लिए आपके पास आवश्यक अनुमति नहीं है।';

  @override
  String get notFoundTitle => 'पृष्ठ नहीं मिला';

  @override
  String get notFoundBody => 'आपके द्वारा खोजा गया पृष्ठ उपलब्ध नहीं है।';

  @override
  String get goHome => 'मुख पृष्ठ पर जाएँ';

  @override
  String get errorNetwork =>
      'नेटवर्क उपलब्ध नहीं है। कृपया अपना इंटरनेट कनेक्शन जाँचें।';

  @override
  String get errorTimeout =>
      'सर्वर से उत्तर नहीं मिला। कृपया पुनः प्रयास करें।';

  @override
  String get errorInvalidCredentials => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get errorAccountInactive =>
      'यह खाता सक्रिय नहीं है। कृपया समिति से संपर्क करें।';

  @override
  String get errorAccountBlocked =>
      'यह खाता अवरुद्ध कर दिया गया है। कृपया समिति से संपर्क करें।';

  @override
  String get errorUnauthenticated => 'कृपया पुनः साइन इन करें।';

  @override
  String get errorForbidden => 'यह कार्य करने की अनुमति नहीं है।';

  @override
  String get errorNotFound => 'अनुरोधित जानकारी नहीं मिली।';

  @override
  String get errorValidation => 'दर्ज की गई जानकारी में त्रुटि है।';

  @override
  String get errorTooManyRequests =>
      'बहुत अधिक प्रयास। कृपया कुछ देर बाद पुनः प्रयास करें।';

  @override
  String get errorSessionExpired =>
      'सत्र समाप्त हो गया है। कृपया पृष्ठ पुनः लोड करें।';

  @override
  String get errorServer => 'सर्वर में त्रुटि हुई। कृपया बाद में प्रयास करें।';

  @override
  String get errorUnknown => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get navAbout => 'हमारे बारे में';

  @override
  String get navContact => 'संपर्क';

  @override
  String get heroDarshan => 'दर्शन करें';

  @override
  String get sectionAbout => 'हमारे बारे में';

  @override
  String get sectionAddress => 'पता एवं संपर्क';

  @override
  String get sectionReadMore => 'और पढ़ें';

  @override
  String get contactPhone => 'दूरभाष';

  @override
  String get contactEmail => 'ईमेल';

  @override
  String get contactMap => 'मानचित्र पर देखें';

  @override
  String get fallbackNotice => 'यह सामग्री अभी केवल हिन्दी में उपलब्ध है।';

  @override
  String get contentComingSoon => 'यह जानकारी शीघ्र ही जोड़ी जाएगी।';

  @override
  String get addressComingSoon => 'पता शीघ्र ही जोड़ा जाएगा।';

  @override
  String get adminContent => 'सामग्री प्रबंधन';

  @override
  String get adminPagesTitle => 'पृष्ठ';

  @override
  String get adminPagesSubtitle =>
      'सार्वजनिक वेबसाइट की सामग्री यहाँ से संपादित करें।';

  @override
  String get adminEditPage => 'पृष्ठ संपादित करें';

  @override
  String get statusDraft => 'मसौदा';

  @override
  String get statusPublished => 'प्रकाशित';

  @override
  String get fieldTitleHindi => 'शीर्षक (हिन्दी)';

  @override
  String get fieldTitleEnglish => 'शीर्षक (अंग्रेज़ी)';

  @override
  String get fieldContentHindi => 'सामग्री (हिन्दी)';

  @override
  String get fieldContentEnglish => 'सामग्री (अंग्रेज़ी)';

  @override
  String get fieldMetaTitle => 'एसईओ शीर्षक';

  @override
  String get fieldMetaDescription => 'एसईओ विवरण';

  @override
  String get fieldOptional => 'वैकल्पिक';

  @override
  String get hindiRequiredHint =>
      'हिन्दी अनिवार्य है। अंग्रेज़ी न होने पर हिन्दी दिखाई जाएगी।';

  @override
  String get actionSave => 'सहेजें';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionPublish => 'प्रकाशित करें';

  @override
  String get actionUnpublish => 'अप्रकाशित करें';

  @override
  String get saveSuccess => 'परिवर्तन सहेज लिए गए।';

  @override
  String get englishMissingBadge => 'अंग्रेज़ी अनुपलब्ध';

  @override
  String get dashboardWelcome => 'प्रबंधन डैशबोर्ड';

  @override
  String get dashboardSubtitle =>
      'अपनी अनुमति के अनुसार उपलब्ध विकल्प नीचे दिए गए हैं।';

  @override
  String get dashboardNoAccess =>
      'आपके खाते को अभी किसी प्रबंधन सुविधा की अनुमति नहीं है।';

  @override
  String get navUsers => 'सदस्य खाते';

  @override
  String get navUsersDesc => 'समिति सदस्यों के खाते बनाएँ और प्रबंधित करें';

  @override
  String get navRoles => 'भूमिका एवं अनुमति';

  @override
  String get navRolesDesc =>
      'प्रत्येक भूमिका क्या कर सकती है, यह निर्धारित करें';

  @override
  String get navPagesDesc => 'सार्वजनिक वेबसाइट की सामग्री संपादित करें';

  @override
  String get navSiteSettings => 'साइट सेटिंग्स';

  @override
  String get navSiteSettingsDesc => 'टैगलाइन, पता, मेन्यू और फुटर';

  @override
  String get usersTitle => 'सदस्य खाते';

  @override
  String get usersSubtitle => 'समिति सदस्यों के खाते यहाँ से प्रबंधित करें।';

  @override
  String get userNew => 'नया खाता';

  @override
  String get userEdit => 'खाता संपादित करें';

  @override
  String get userCreate => 'खाता बनाएँ';

  @override
  String get userNeverSignedIn => 'कभी साइन इन नहीं किया';

  @override
  String get userLastLogin => 'अंतिम लॉगिन';

  @override
  String get fieldFirstName => 'नाम';

  @override
  String get fieldLastName => 'उपनाम';

  @override
  String get fieldMobile => 'मोबाइल';

  @override
  String get fieldRole => 'भूमिका';

  @override
  String get fieldStatus => 'स्थिति';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusInactive => 'निष्क्रिय';

  @override
  String get statusBlocked => 'अवरुद्ध';

  @override
  String get userPasswordHint =>
      'नया सदस्य ईमेल पर भेजे गए लिंक से अपना पासवर्ड स्वयं बनाएगा।';

  @override
  String get userSendReset => 'पासवर्ड लिंक भेजें';

  @override
  String get userResetSent => 'पासवर्ड लिंक भेज दिया गया।';

  @override
  String get userCreated => 'खाता बना दिया गया और पासवर्ड लिंक भेज दिया गया।';

  @override
  String get rolesTitle => 'भूमिका एवं अनुमति';

  @override
  String get rolesSubtitle => 'प्रत्येक भूमिका किन मॉड्यूल तक पहुँच सकती है।';

  @override
  String roleMembers(int count) {
    return '$count खाते';
  }

  @override
  String rolePermissionCount(int count) {
    return '$count अनुमतियाँ';
  }

  @override
  String get roleFixed => 'सुपर एडमिन को सदैव सभी अनुमतियाँ रहती हैं।';

  @override
  String get rolePermissionsTitle => 'अनुमतियाँ';

  @override
  String get permissionsSaved => 'अनुमतियाँ सहेज ली गईं।';

  @override
  String modulePhasePending(int phase) {
    return 'चरण $phase में उपलब्ध होगा';
  }

  @override
  String get loginHistoryTitle => 'लॉगिन इतिहास';

  @override
  String get loginHistoryEmpty => 'अभी कोई लॉगिन दर्ज नहीं है।';

  @override
  String get loginSuccess => 'सफल';

  @override
  String get loginFailed => 'असफल';

  @override
  String get resetPasswordTitle => 'नया पासवर्ड बनाएँ';

  @override
  String get resetPasswordSubtitle => 'अपने खाते के लिए नया पासवर्ड दर्ज करें।';

  @override
  String get fieldNewPassword => 'नया पासवर्ड';

  @override
  String get fieldConfirmPassword => 'पासवर्ड दोबारा दर्ज करें';

  @override
  String get passwordsDoNotMatch => 'दोनों पासवर्ड एक जैसे नहीं हैं';

  @override
  String get resetPasswordDone => 'पासवर्ड बदल दिया गया। अब साइन इन करें।';

  @override
  String get resetLinkInvalid => 'यह लिंक अमान्य है या समाप्त हो चुका है।';

  @override
  String get siteSettingsTitle => 'साइट सेटिंग्स';

  @override
  String get siteSettingsSubtitle => 'मुख पृष्ठ की पंक्ति, पता और फुटर।';

  @override
  String get fieldTagline => 'टैगलाइन';

  @override
  String get fieldFooter => 'फुटर पंक्ति';

  @override
  String get fieldVillage => 'गाँव';

  @override
  String get fieldPanchayat => 'पंचायत';

  @override
  String get fieldPoliceStation => 'थाना';

  @override
  String get fieldDistrict => 'जिला';

  @override
  String get fieldState => 'राज्य';

  @override
  String get fieldPostalCode => 'पिन कोड';

  @override
  String get fieldContactPhone => 'संपर्क दूरभाष';

  @override
  String get fieldContactEmail => 'संपर्क ईमेल';
}
