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
}
