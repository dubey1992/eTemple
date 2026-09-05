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
  String get invocation => 'राधे राधे · जय श्री कृष्ण';

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

  @override
  String get navTempleProfile => 'मंदिर प्रोफ़ाइल';

  @override
  String get navTempleProfileDesc => 'मंदिर का नाम, पता, इतिहास और उद्देश्य';

  @override
  String get navCommittee => 'प्रबंध समिति';

  @override
  String get navCommitteeDesc => 'सदस्य, कार्यकाल और सार्वजनिक दृश्यता';

  @override
  String get sectionCommittee => 'प्रबंध समिति';

  @override
  String get sectionHistory => 'मंदिर का इतिहास';

  @override
  String get sectionMission => 'हमारा उद्देश्य';

  @override
  String get committeeTitle => 'प्रबंध समिति';

  @override
  String get committeeSubtitle => 'मंदिर की देखरेख करने वाले समिति सदस्य।';

  @override
  String get committeeComingSoon => 'समिति की जानकारी शीघ्र ही जोड़ी जाएगी।';

  @override
  String get viewCommittee => 'पूरी समिति देखें';

  @override
  String get panchayatLabel => 'पंचायत';

  @override
  String establishedIn(int year) {
    return 'स्थापना: $year';
  }

  @override
  String tenureSince(String from) {
    return 'कार्यकाल: $from से';
  }

  @override
  String tenureRange(String from, String to) {
    return 'कार्यकाल: $from – $to';
  }

  @override
  String get sectionContact => 'संपर्क विवरण';

  @override
  String get addressLivesInTempleProfile =>
      'पता अब मंदिर प्रोफ़ाइल में रखा जाता है, ताकि वह केवल एक ही स्थान पर रहे।';

  @override
  String get templeProfileTitle => 'मंदिर प्रोफ़ाइल';

  @override
  String get templeProfileSubtitle =>
      'मंदिर का नाम, पता और परिचय। यही नाम वेबसाइट के शीर्ष पर दिखाया जाता है।';

  @override
  String get sectionIdentity => 'पहचान';

  @override
  String get fieldTempleName => 'मंदिर का नाम';

  @override
  String get fieldHistory => 'इतिहास';

  @override
  String get fieldMission => 'उद्देश्य';

  @override
  String get fieldAddressLine1 => 'पता पंक्ति 1';

  @override
  String get fieldAddressLine2 => 'पता पंक्ति 2';

  @override
  String get fieldCountry => 'देश';

  @override
  String get fieldLogoUrl => 'लोगो का URL';

  @override
  String get fieldMapUrl => 'मानचित्र का URL';

  @override
  String get fieldEstablishedYear => 'स्थापना वर्ष';

  @override
  String get templeNameHint =>
      'यह नाम वेबसाइट के शीर्षक, हेडर और फुटर में उपयोग होता है। खाली रहने पर ऐप का डिफ़ॉल्ट नाम दिखेगा।';

  @override
  String get committeeAdminTitle => 'प्रबंध समिति';

  @override
  String get committeeAdminSubtitle =>
      'समिति सदस्य जोड़ें और तय करें कि उनकी कौन-सी जानकारी सार्वजनिक हो।';

  @override
  String get committeeEmpty => 'अभी कोई सदस्य दर्ज नहीं है।';

  @override
  String get memberNew => 'नया सदस्य';

  @override
  String get memberEdit => 'सदस्य संपादित करें';

  @override
  String get memberCreate => 'सदस्य जोड़ें';

  @override
  String get memberCreated => 'सदस्य जोड़ दिया गया।';

  @override
  String get memberDeleted => 'सदस्य हटा दिया गया।';

  @override
  String get memberDelete => 'सदस्य हटाएँ';

  @override
  String get memberDeleteConfirmTitle => 'सदस्य हटाएँ?';

  @override
  String get memberDeleteConfirmBody =>
      'इससे रिकॉर्ड स्थायी रूप से मिट जाएगा। यदि केवल कार्यकाल समाप्त हुआ है तो \"कार्यकाल समाप्त\" तिथि भरें — रिकॉर्ड सुरक्षित रहेगा।';

  @override
  String get memberTenureEnded => 'कार्यकाल समाप्त';

  @override
  String get memberNotPublished => 'अप्रकाशित';

  @override
  String get actionDelete => 'हटाएँ';

  @override
  String get fieldName => 'नाम';

  @override
  String get fieldDesignation => 'पद';

  @override
  String get fieldBio => 'परिचय';

  @override
  String get fieldPhone => 'दूरभाष';

  @override
  String get fieldEmail => 'ईमेल';

  @override
  String get fieldPhotoUrl => 'फ़ोटो का URL';

  @override
  String get fieldTenureStart => 'कार्यकाल आरंभ';

  @override
  String get fieldTenureEnd => 'कार्यकाल समाप्त';

  @override
  String get fieldSortOrder => 'क्रम';

  @override
  String get fieldPublished => 'सार्वजनिक वेबसाइट पर दिखाएँ';

  @override
  String get dateHint => 'YYYY-MM-DD';

  @override
  String get consentTitle => 'व्यक्तिगत जानकारी की सहमति';

  @override
  String get consentExplain =>
      'दूरभाष, ईमेल और फ़ोटो तभी सार्वजनिक होंगे जब सदस्य की सहमति दर्ज हो। सहमति हटाते ही तीनों तुरंत छिप जाते हैं।';

  @override
  String get consentRecorded => 'सदस्य की सहमति दर्ज है';

  @override
  String consentRecordedOn(String date) {
    return 'सहमति दर्ज: $date';
  }

  @override
  String get consentMissingHint =>
      'सहमति दर्ज किए बिना कोई भी व्यक्तिगत विवरण सार्वजनिक नहीं किया जा सकता।';

  @override
  String get showPhonePublicly => 'दूरभाष सार्वजनिक रूप से दिखाएँ';

  @override
  String get showEmailPublicly => 'ईमेल सार्वजनिक रूप से दिखाएँ';

  @override
  String get showPhotoPublicly => 'फ़ोटो सार्वजनिक रूप से दिखाएँ';

  @override
  String get consentPublicWarning => 'व्यक्तिगत विवरण सार्वजनिक';

  @override
  String get sectionTenure => 'कार्यकाल';

  @override
  String get actionBack => 'वापस';

  @override
  String get valueNotAvailable => 'NA';

  @override
  String get navEvents => 'पूजा एवं कार्यक्रम';

  @override
  String get navEventsDesc => 'आरती, भजन-कीर्तन, उत्सव और कैलेंडर';

  @override
  String get eventsTitle => 'पूजा एवं कार्यक्रम';

  @override
  String get eventsSubtitle =>
      'मंदिर की दैनिक आरती, साप्ताहिक कीर्तन और आगामी उत्सव।';

  @override
  String get sectionEvents => 'आगामी कार्यक्रम';

  @override
  String get viewUpcoming => 'आगामी';

  @override
  String get viewPast => 'पूर्व कार्यक्रम';

  @override
  String get noUpcomingEvents => 'अभी कोई आगामी कार्यक्रम निर्धारित नहीं है।';

  @override
  String get noPastEvents => 'अभी कोई पूर्व कार्यक्रम दर्ज नहीं है।';

  @override
  String get viewAllEvents => 'सभी कार्यक्रम देखें';

  @override
  String get eventCancelled => 'रद्द';

  @override
  String get eventCancelledNotice => 'यह कार्यक्रम रद्द कर दिया गया है।';

  @override
  String get eventVenue => 'स्थान';

  @override
  String get eventUpcomingDates => 'आगामी तिथियाँ';

  @override
  String get eventNotFound => 'यह कार्यक्रम उपलब्ध नहीं है।';

  @override
  String get eventTypeAarti => 'आरती';

  @override
  String get eventTypeBhajanKirtan => 'भजन-कीर्तन';

  @override
  String get eventTypeFestival => 'उत्सव';

  @override
  String get eventTypePuja => 'पूजा';

  @override
  String get eventTypeOther => 'अन्य';

  @override
  String get recurrenceNone => 'एक बार';

  @override
  String get recurrenceDaily => 'प्रतिदिन';

  @override
  String get recurrenceWeekly => 'साप्ताहिक';

  @override
  String get recurrenceMonthly => 'मासिक';

  @override
  String get recurrenceYearly => 'वार्षिक';

  @override
  String get weekdayMon => 'सोम';

  @override
  String get weekdayTue => 'मंगल';

  @override
  String get weekdayWed => 'बुध';

  @override
  String get weekdayThu => 'गुरु';

  @override
  String get weekdayFri => 'शुक्र';

  @override
  String get weekdaySat => 'शनि';

  @override
  String get weekdaySun => 'रवि';

  @override
  String get eventsAdminTitle => 'पूजा एवं कार्यक्रम';

  @override
  String get eventsAdminSubtitle =>
      'आरती, कीर्तन और उत्सव यहाँ से जोड़ें। दोहराने वाला कार्यक्रम एक ही बार दर्ज करें।';

  @override
  String get eventsEmpty => 'अभी कोई कार्यक्रम दर्ज नहीं है।';

  @override
  String get eventNew => 'नया कार्यक्रम';

  @override
  String get eventEdit => 'कार्यक्रम संपादित करें';

  @override
  String get eventCreate => 'कार्यक्रम जोड़ें';

  @override
  String get eventCreated => 'कार्यक्रम जोड़ दिया गया।';

  @override
  String get eventDeleted => 'कार्यक्रम हटा दिया गया।';

  @override
  String get eventDelete => 'कार्यक्रम हटाएँ';

  @override
  String get eventDeleteConfirmTitle => 'कार्यक्रम हटाएँ?';

  @override
  String get eventDeleteConfirmBody =>
      'इससे रिकॉर्ड स्थायी रूप से मिट जाएगा। यदि कार्यक्रम केवल रद्द हुआ है तो स्थिति \"रद्द\" चुनें — तब भक्तों को सूचना मिलती रहेगी।';

  @override
  String get statusCancelled => 'रद्द';

  @override
  String get filterAll => 'सभी';

  @override
  String get fieldEventType => 'कार्यक्रम का प्रकार';

  @override
  String get fieldEventTitle => 'कार्यक्रम का नाम';

  @override
  String get fieldEventDescription => 'विवरण';

  @override
  String get fieldVenue => 'स्थान';

  @override
  String get fieldStartAt => 'आरंभ';

  @override
  String get fieldEndAt => 'समाप्ति';

  @override
  String get fieldRecurrence => 'दोहराव';

  @override
  String get fieldRecurrenceDays => 'किन दिनों';

  @override
  String get fieldRecurrenceUntil => 'इस तिथि तक';

  @override
  String get fieldPosterUrl => 'पोस्टर का URL';

  @override
  String get fieldFeatured => 'मुख पृष्ठ पर दिखाएँ';

  @override
  String get recurringHint =>
      'दोहराने वाला कार्यक्रम एक ही बार दर्ज होता है — दैनिक आरती के लिए 365 प्रविष्टियाँ नहीं बनानी पड़तीं।';

  @override
  String get pickDate => 'तिथि चुनें';

  @override
  String get pickTime => 'समय चुनें';

  @override
  String get clearEndTime => 'समाप्ति हटाएँ';

  @override
  String get viewEvents => 'कार्यक्रम देखें';

  @override
  String get navGallery => 'गैलरी';

  @override
  String get galleryTitle => 'फोटो गैलरी';

  @override
  String get gallerySubtitle =>
      'मंदिर, पूजा, त्योहार और ग्राम कार्यक्रमों की तस्वीरें यहाँ दिखाई जाएंगी।';

  @override
  String get sectionGallery => 'फोटो गैलरी';

  @override
  String get viewGallery => 'पूरी गैलरी देखें';

  @override
  String get galleryPhotos => 'तस्वीरें';

  @override
  String get galleryVideos => 'वीडियो दर्शन';

  @override
  String get galleryAllAlbums => 'सभी';

  @override
  String get noPhotos => 'अभी कोई तस्वीर प्रकाशित नहीं हुई है।';

  @override
  String get noVideos => 'अभी कोई वीडियो दर्शन उपलब्ध नहीं है।';

  @override
  String get galleryLoadMore => 'और तस्वीरें दिखाएँ';

  @override
  String get imageUnavailable => 'चित्र लोड नहीं हो सका';

  @override
  String get actionClose => 'बंद करें';

  @override
  String get openInYoutube => 'यूट्यूब पर देखें';

  @override
  String get videoDarshanNotice =>
      'वीडियो यूट्यूब पर होस्ट है; चलाने पर यूट्यूब की शर्तें लागू होंगी।';

  @override
  String get navMedia => 'गैलरी एवं वीडियो';

  @override
  String get navMediaDesc =>
      'तस्वीरें और वीडियो अपलोड, प्रकाशित और क्रमबद्ध करें';

  @override
  String get mediaAdminTitle => 'गैलरी एवं वीडियो';

  @override
  String get mediaAdminSubtitle =>
      'तस्वीरें यहाँ अपलोड करें और वीडियो लिंक जोड़ें। अपलोड की गई हर तस्वीर से स्थान एवं कैमरा जानकारी स्वतः हटा दी जाती है।';

  @override
  String get mediaEmpty => 'अभी कोई मीडिया नहीं जोड़ा गया है।';

  @override
  String get mediaNew => 'नया मीडिया';

  @override
  String get mediaEdit => 'मीडिया संपादित करें';

  @override
  String get mediaUploadPhoto => 'तस्वीर अपलोड करें';

  @override
  String get mediaAddVideo => 'वीडियो लिंक जोड़ें';

  @override
  String get mediaChooseFile => 'फ़ाइल चुनें';

  @override
  String mediaFileHint(int size) {
    return 'JPEG, PNG या WebP · अधिकतम $size MB';
  }

  @override
  String get mediaNoFileChosen => 'कोई फ़ाइल नहीं चुनी गई';

  @override
  String mediaFileSelected(String name, String size) {
    return '$name · $size';
  }

  @override
  String get mediaFileRequired => 'अपलोड करने के लिए एक तस्वीर चुनें।';

  @override
  String get mediaChooserUnavailable =>
      'फ़ाइल चयन केवल ब्राउज़र में उपलब्ध है।';

  @override
  String get mediaTypePhoto => 'तस्वीर';

  @override
  String get mediaTypeVideo => 'वीडियो';

  @override
  String get mediaDelete => 'मीडिया हटाएँ';

  @override
  String get mediaDeleteConfirmTitle => 'यह मीडिया हटाएँ?';

  @override
  String get mediaDeleteConfirmBody =>
      'फ़ाइल स्थायी रूप से मिट जाएगी। यदि इसे केवल छिपाना है तो प्रकाशन हटाएँ।';

  @override
  String get mediaDeleted => 'मीडिया हटा दिया गया।';

  @override
  String get mediaInUseTitle => 'यह फ़ाइल अभी उपयोग में है';

  @override
  String get mediaInUseBody =>
      'नीचे दिए गए स्थानों से हटाने के बाद ही इसे मिटाया जा सकता है। तब तक इसका प्रकाशन हटाया जा सकता है।';

  @override
  String get mediaReferenceEventPoster => 'कार्यक्रम पोस्टर';

  @override
  String get mediaReferenceCommitteeMember => 'समिति सदस्य';

  @override
  String get mediaReferenceTempleLogo => 'मंदिर का लोगो';

  @override
  String get mediaReferenceAlbumCover => 'एल्बम कवर';

  @override
  String get mediaReferencePage => 'पृष्ठ';

  @override
  String get mediaMoveUp => 'ऊपर ले जाएँ';

  @override
  String get mediaMoveDown => 'नीचे ले जाएँ';

  @override
  String get mediaOrderSaved => 'क्रम सहेजा गया।';

  @override
  String get fieldCaptionHindi => 'कैप्शन (हिन्दी)';

  @override
  String get fieldCaptionEnglish => 'कैप्शन (अंग्रेज़ी)';

  @override
  String get fieldVideoUrl => 'यूट्यूब लिंक';

  @override
  String get videoUrlHint => 'केवल यूट्यूब लिंक जोड़े जा सकते हैं।';

  @override
  String get navAlbums => 'एल्बम';

  @override
  String get navAlbumsDesc =>
      'तस्वीरों को त्योहार या अवसर के अनुसार समूह में रखें';

  @override
  String get albumsAdminTitle => 'एल्बम';

  @override
  String get albumsAdminSubtitle =>
      'तस्वीरों को त्योहार या अवसर के अनुसार समूह में रखें। एल्बम हटाने पर तस्वीरें बनी रहती हैं।';

  @override
  String get albumsEmpty => 'अभी कोई एल्बम नहीं बनाया गया है।';

  @override
  String get albumNew => 'नया एल्बम';

  @override
  String get albumEdit => 'एल्बम संपादित करें';

  @override
  String get albumDelete => 'एल्बम हटाएँ';

  @override
  String get albumDeleteConfirmTitle => 'यह एल्बम हटाएँ?';

  @override
  String get albumDeleteConfirmBody =>
      'एल्बम हट जाएगा, पर उसकी तस्वीरें बनी रहेंगी।';

  @override
  String get albumDeleted => 'एल्बम हटा दिया गया।';

  @override
  String get albumNone => 'किसी एल्बम में नहीं';

  @override
  String albumItemCount(int count) {
    return '$count तस्वीरें';
  }

  @override
  String get fieldAlbum => 'एल्बम';

  @override
  String get fieldSlug => 'यूआरएल नाम';

  @override
  String get slugHint => 'खाली छोड़ने पर स्वतः बना दिया जाएगा।';

  @override
  String get fieldDescriptionHindi => 'विवरण (हिन्दी)';

  @override
  String get fieldDescriptionEnglish => 'विवरण (अंग्रेज़ी)';

  @override
  String get fieldCoverPhoto => 'कवर तस्वीर';

  @override
  String get mediaPickerChoose => 'गैलरी से चुनें';

  @override
  String get mediaPickerClear => 'हटाएँ';

  @override
  String get mediaPickerEmpty => 'गैलरी में अभी कोई प्रकाशित तस्वीर नहीं है।';

  @override
  String get mediaPickerHint =>
      'गैलरी से चुनें, या नीचे कोई बाहरी यूआरएल लिखें।';

  @override
  String get navDonate => 'दान';

  @override
  String get donateTitle => 'मंदिर सहयोग / दान';

  @override
  String get donateSubtitle =>
      'आपका सहयोग मंदिर की पूजा व्यवस्था, रखरखाव, त्योहार और सेवा कार्यों में उपयोग होगा।';

  @override
  String get donateHeading => 'पारदर्शी एवं सामुदायिक दान व्यवस्था';

  @override
  String get donateComingSoon =>
      'दान संबंधी जानकारी शीघ्र ही यहाँ जोड़ी जाएगी।';

  @override
  String get donateAction => 'दान करें';

  @override
  String get viewDonate => 'दान विवरण देखें';

  @override
  String get fieldUpiId => 'UPI ID';

  @override
  String get fieldBankName => 'बैंक';

  @override
  String get fieldAccountName => 'खाता नाम';

  @override
  String get fieldAccountNumber => 'खाता संख्या';

  @override
  String get fieldIfsc => 'IFSC';

  @override
  String get donateQrLabel => 'UPI QR';

  @override
  String donateCopied(String label) {
    return '$label कॉपी हो गया।';
  }

  @override
  String get actionCopy => 'कॉपी करें';

  @override
  String get navDonations => 'दान एवं रसीदें';

  @override
  String get navDonationsDesc =>
      'दान दर्ज करें, सत्यापित करें और रसीद जारी करें';

  @override
  String get donationsAdminTitle => 'दान एवं रसीदें';

  @override
  String get donationsAdminSubtitle =>
      'दान यहाँ दर्ज करें। सत्यापन के बाद रसीद संख्या जारी होती है और उसके बाद विवरण नहीं बदला जा सकता।';

  @override
  String get donationsEmpty => 'अभी कोई दान दर्ज नहीं किया गया है।';

  @override
  String get donationNew => 'नया दान दर्ज करें';

  @override
  String get donationEdit => 'दान विवरण';

  @override
  String get donationSearchHint => 'नाम, रसीद संख्या या संदर्भ खोजें';

  @override
  String get summaryReceived => 'कुल प्राप्त दान';

  @override
  String get summaryPending => 'सत्यापन शेष';

  @override
  String get summaryDonors => 'दानदाता';

  @override
  String get summaryReversed => 'निरस्त';

  @override
  String get statusPending => 'सत्यापन शेष';

  @override
  String get statusReversed => 'निरस्त';

  @override
  String get statusConfirmed => 'सत्यापित';

  @override
  String get fieldDonorName => 'दानदाता का नाम';

  @override
  String get fieldDonorPhone => 'दूरभाष';

  @override
  String get fieldDonorAddress => 'पता';

  @override
  String get fieldAmount => 'राशि (₹)';

  @override
  String get amountHint => 'जैसे 501 या 501.50';

  @override
  String get fieldDonationDate => 'दान की तिथि';

  @override
  String get fieldPaymentMode => 'भुगतान माध्यम';

  @override
  String get fieldReferenceNumber => 'संदर्भ संख्या';

  @override
  String get referenceHint =>
      'नकद के अलावा हर माध्यम के लिए आवश्यक — UPI संदर्भ, चेक संख्या या ट्रांसफर आईडी।';

  @override
  String get fieldPurpose => 'उद्देश्य';

  @override
  String get fieldNotes => 'टिप्पणी';

  @override
  String get fieldAnonymous => 'दानदाता का नाम सार्वजनिक न करें';

  @override
  String get anonymousHint =>
      'रसीद पर नाम फिर भी रहेगा — वह दानदाता की अपनी रसीद है।';

  @override
  String get modeCash => 'नकद';

  @override
  String get modeUpi => 'UPI';

  @override
  String get modeBankTransfer => 'बैंक ट्रांसफर';

  @override
  String get modeCheque => 'चेक';

  @override
  String get modeCard => 'कार्ड';

  @override
  String get modeOther => 'अन्य';

  @override
  String get purposeGeneral => 'सामान्य';

  @override
  String get purposePuja => 'पूजा व्यवस्था';

  @override
  String get purposeMaintenance => 'रखरखाव';

  @override
  String get purposeFestival => 'त्योहार';

  @override
  String get purposeAnnadan => 'भंडारा एवं प्रसाद';

  @override
  String get purposeConstruction => 'निर्माण कार्य';

  @override
  String get purposeOther => 'अन्य';

  @override
  String get fieldReceiptNumber => 'रसीद संख्या';

  @override
  String get receiptNotIssued => 'सत्यापन के बाद जारी होगी';

  @override
  String get donationConfirm => 'सत्यापित करें';

  @override
  String get donationConfirmTitle => 'इस दान को सत्यापित करें?';

  @override
  String get donationConfirmBody =>
      'सत्यापित करते ही रसीद संख्या जारी हो जाएगी और उसके बाद राशि, तिथि या दानदाता का नाम नहीं बदला जा सकेगा।';

  @override
  String donationConfirmed(String receipt) {
    return 'दान सत्यापित। रसीद संख्या $receipt जारी हुई।';
  }

  @override
  String get donationReverse => 'दान निरस्त करें';

  @override
  String get donationReverseTitle => 'इस दान को निरस्त करें?';

  @override
  String get donationReverseBody =>
      'प्रविष्टि मिटाई नहीं जाती — वह रसीद संख्या सहित बनी रहती है और किसी योग में नहीं गिनी जाती। कारण लिखना आवश्यक है।';

  @override
  String get fieldReversalReason => 'निरस्त करने का कारण';

  @override
  String get donationReversed => 'दान निरस्त कर दिया गया।';

  @override
  String get donationRecorded => 'दान दर्ज हो गया।';

  @override
  String get donationPrintReceipt => 'रसीद प्रिंट करें';

  @override
  String get donationLockedNotice =>
      'रसीद जारी हो चुकी है, इसलिए अब केवल टिप्पणी बदली जा सकती है। सुधार के लिए इसे निरस्त करके दोबारा दर्ज करें।';

  @override
  String donationReversedNotice(String date, String reason) {
    return 'यह दान $date को निरस्त किया गया: $reason';
  }

  @override
  String get recordedByLabel => 'दर्ज किया';

  @override
  String get confirmedByLabel => 'सत्यापित किया';

  @override
  String get navDonationSettings => 'दान विवरण';

  @override
  String get navDonationSettingsDesc =>
      'UPI, बैंक विवरण और QR जो वेबसाइट पर दिखते हैं';

  @override
  String get donationSettingsTitle => 'दान विवरण';

  @override
  String get donationSettingsSubtitle =>
      'ये विवरण वेबसाइट के दान अनुभाग में दिखाई देते हैं। खाता संख्या ठीक वैसी ही दिखेगी जैसी यहाँ लिखी जाए — छिपाना है तो स्वयं छिपाकर लिखें।';

  @override
  String get donationSettingsSaved => 'दान विवरण सहेज दिए गए।';

  @override
  String get fieldQrImage => 'UPI QR चित्र';

  @override
  String get fieldDonateIntroHindi => 'परिचय (हिन्दी)';

  @override
  String get fieldDonateIntroEnglish => 'परिचय (अंग्रेज़ी)';

  @override
  String get fieldDonateNoteHindi => 'सूचना (हिन्दी)';

  @override
  String get fieldDonateNoteEnglish => 'सूचना (अंग्रेज़ी)';

  @override
  String get fieldPublishDonationDetails => 'वेबसाइट पर दिखाएँ';

  @override
  String get donationSettingsIncomplete =>
      'प्रकाशित है, पर कोई भुगतान विवरण नहीं भरा गया — इसलिए वेबसाइट पर कुछ नहीं दिखेगा।';

  @override
  String get mediaReferenceDonationQr => 'दान QR';

  @override
  String get errorDonationLocked => 'यह प्रविष्टि अब बदली नहीं जा सकती।';

  @override
  String paginationPage(int current, int last) {
    return 'पृष्ठ $current / $last';
  }

  @override
  String get actionPrevious => 'पिछला';

  @override
  String get actionNext => 'अगला';

  @override
  String get contactPageTitle => 'मंदिर को लिखें';

  @override
  String get contactPageSubtitle =>
      'पूजा, कार्यक्रम या किसी भी विषय में पूछें। समिति का कोई सदस्य आपसे संपर्क करेगा।';

  @override
  String get contactFormTitle => 'संदेश भेजें';

  @override
  String get contactOtherWays => 'संपर्क के अन्य माध्यम';

  @override
  String get contactOpenForm => 'समिति को लिखें';

  @override
  String get fieldYourName => 'आपका नाम';

  @override
  String get fieldEnquiryCategory => 'विषय क्या है?';

  @override
  String get fieldEnquiryMessage => 'आपका संदेश';

  @override
  String get fieldPreferredLanguage => 'उत्तर किस भाषा में चाहिए';

  @override
  String get contactChannelHint =>
      'मोबाइल नंबर या ईमेल अवश्य दें, ताकि समिति उत्तर दे सके।';

  @override
  String get actionSendMessage => 'संदेश भेजें';

  @override
  String get actionSendAnother => 'एक और संदेश भेजें';

  @override
  String get enquirySentTitle => 'आपका संदेश भेज दिया गया है';

  @override
  String get enquirySentBody =>
      'समिति का कोई सदस्य शीघ्र ही संपर्क करेगा। यह संदर्भ संख्या सुरक्षित रखें — इसी से मंदिर आपका संदेश ढूँढ़ेगा।';

  @override
  String get enquiryReferenceLabel => 'संदर्भ संख्या';

  @override
  String get enquiryChallengeLabel => 'भेजने से पहले एक छोटा सा प्रश्न';

  @override
  String get fieldChallengeAnswer => 'आपका उत्तर';

  @override
  String get enquiryCategoryGeneral => 'सामान्य जानकारी';

  @override
  String get enquiryCategoryPujaBooking => 'पूजा बुकिंग';

  @override
  String get enquiryCategoryDonation => 'दान संबंधी';

  @override
  String get enquiryCategoryEvent => 'कार्यक्रम संबंधी';

  @override
  String get enquiryCategoryVolunteer => 'सेवा एवं सहयोग';

  @override
  String get enquiryCategorySuggestion => 'सुझाव';

  @override
  String get enquiryCategoryComplaint => 'शिकायत';

  @override
  String get enquiryCategoryOther => 'अन्य';

  @override
  String get enquiryStatusNew => 'नया';

  @override
  String get enquiryStatusInProgress => 'कार्यवाही में';

  @override
  String get enquiryStatusResolved => 'उत्तर दिया गया';

  @override
  String get enquiryStatusSpam => 'स्पैम';

  @override
  String get navEnquiries => 'संपर्क एवं पूछताछ';

  @override
  String get navEnquiriesDesc =>
      'भक्तों द्वारा भेजे गए संदेश और उन पर की गई कार्यवाही';

  @override
  String get enquiryInboxTitle => 'पूछताछ इनबॉक्स';

  @override
  String get enquiryInboxSubtitle =>
      'संपर्क फ़ॉर्म से आए संदेश। इनमें से कुछ भी सार्वजनिक वेबसाइट पर नहीं दिखता।';

  @override
  String get enquiryInboxEmpty => 'अभी तक कोई संदेश नहीं।';

  @override
  String get enquiryDetailTitle => 'पूछताछ';

  @override
  String get enquiryAssignedTo => 'सौंपा गया';

  @override
  String get enquiryUnassigned => 'किसी को नहीं सौंपा गया';

  @override
  String get enquiryReplyIn => 'उत्तर चाहिए';

  @override
  String enquiryReceivedOn(String date) {
    return 'प्राप्त: $date';
  }

  @override
  String enquiryResolvedOn(String date) {
    return 'उत्तर दिया: $date';
  }

  @override
  String enquiryOpenCount(int count) {
    return '$count प्रतीक्षारत';
  }

  @override
  String get enquiryStatusUpdated => 'स्थिति बदल दी गई।';

  @override
  String get enquiryAssignmentUpdated => 'जिम्मेदारी बदल दी गई।';

  @override
  String get enquirySearchHint => 'संदर्भ, नाम, नंबर या संदेश खोजें';

  @override
  String get enquiryNoReplyChannel => 'कोई संपर्क विवरण नहीं दिया गया';

  @override
  String get enquirySpamNotice =>
      'स्पैम चिह्नित। यह सुरक्षित है, पर इनबॉक्स से हटा दिया गया है।';

  @override
  String get enquiryPrivacyNotice => 'ये संदेश केवल समिति के लिए हैं।';

  @override
  String get errorEnquiryFormExpired =>
      'यह फ़ॉर्म समाप्त हो गया है। कृपया संदेश दोबारा भेजें।';

  @override
  String get errorEnquiryChallengeRequired =>
      'कृपया फ़ॉर्म के साथ दिया गया छोटा प्रश्न हल करें।';

  @override
  String get enquiryAssignToMe => 'मुझे सौंपें';

  @override
  String get enquiryUnassign => 'जिम्मेदारी हटाएं';

  @override
  String get enquiryChooseMember => 'किसी सदस्य को सौंपें';

  @override
  String get navAnnouncements => 'सूचनाएं';

  @override
  String get navAnnouncementsDesc =>
      'वेबसाइट की सूचनाएं, और उन्हें समिति को भेजना';

  @override
  String get announcementsTitle => 'सूचनाएं';

  @override
  String get announcementsSubtitle =>
      'वेबसाइट पर क्या दिख रहा है, क्या निर्धारित है, और क्या भेजा जा चुका है।';

  @override
  String get announcementsEmpty => 'अभी तक कोई सूचना नहीं।';

  @override
  String get announcementNew => 'नई सूचना लिखें';

  @override
  String get announcementEdit => 'सूचना संपादित करें';

  @override
  String get announcementSaved => 'सूचना सहेजी गई।';

  @override
  String get announcementPublished =>
      'प्रकाशित। निर्धारित अवधि में यह वेबसाइट पर दिखेगी।';

  @override
  String get announcementArchived =>
      'संग्रहीत। वेबसाइट से हटा दी गई है, पर सुरक्षित है।';

  @override
  String get announcementStatusDraft => 'मसौदा';

  @override
  String get announcementStatusPublished => 'प्रकाशित';

  @override
  String get announcementStatusArchived => 'संग्रहीत';

  @override
  String get announcementShowingNow => 'अभी वेबसाइट पर';

  @override
  String announcementScheduledFor(String date) {
    return 'आरंभ: $date';
  }

  @override
  String announcementExpiredOn(String date) {
    return 'समाप्त: $date';
  }

  @override
  String get announcementPriorityNormal => 'सामान्य';

  @override
  String get announcementPriorityImportant => 'महत्वपूर्ण';

  @override
  String get announcementPriorityUrgent => 'अत्यावश्यक';

  @override
  String get fieldAnnouncementTitleHindi => 'शीर्षक (हिन्दी)';

  @override
  String get fieldAnnouncementTitleEnglish => 'शीर्षक (अंग्रेज़ी)';

  @override
  String get fieldAnnouncementMessageHindi => 'संदेश (हिन्दी)';

  @override
  String get fieldAnnouncementMessageEnglish => 'संदेश (अंग्रेज़ी)';

  @override
  String get fieldAnnouncementPriority => 'प्राथमिकता';

  @override
  String get fieldAnnouncementStart => 'कब से दिखे';

  @override
  String get fieldAnnouncementEnd => 'कब तक दिखे';

  @override
  String get fieldAnnouncementEndHint =>
      'खाली छोड़ें तो संग्रहीत करने तक दिखती रहेगी';

  @override
  String get fieldAnnouncementLink => 'अधिक जानकारी का लिंक';

  @override
  String get actionPublish2 => 'प्रकाशित करें';

  @override
  String get actionArchive => 'संग्रहीत करें';

  @override
  String get announcementSend => 'यह सूचना भेजें';

  @override
  String get announcementSendTitle => 'यह सूचना भेजें?';

  @override
  String get announcementSendBody =>
      'भेजने पर यह सूचना समिति के हर सक्रिय खाते के इनबॉक्स में पहुंचेगी। इसे वापस नहीं लिया जा सकता, और यह केवल एक बार भेजी जा सकती है।';

  @override
  String get announcementSendConfirm => 'भेज दें';

  @override
  String announcementSent(int count) {
    return '$count समिति सदस्यों को भेजी गई।';
  }

  @override
  String announcementSentOn(String date) {
    return 'भेजी गई: $date';
  }

  @override
  String get announcementSentNotice =>
      'यह सूचना भेजी जा चुकी है और दोबारा नहीं भेजी जा सकती।';

  @override
  String get announcementChannels => 'किस माध्यम से भेजें';

  @override
  String get announcementChannelSite => 'केवल वेबसाइट';

  @override
  String get announcementChannelEmail => 'समिति को ईमेल';

  @override
  String get announcementChannelSms => 'एसएमएस';

  @override
  String get announcementChannelWhatsapp => 'WhatsApp';

  @override
  String get announcementChannelUnavailable => 'किसी प्रदाता से जुड़ा नहीं है';

  @override
  String get announcementRecipientsNote =>
      'ईमेल केवल समिति के खातों को जाता है। मंदिर को संदेश भेजने वाले भक्त किसी मेलिंग सूची में नहीं हैं।';

  @override
  String get announcementPublishBeforeSending =>
      'भेजने से पहले इस सूचना को प्रकाशित करें।';

  @override
  String get announcementSearchHint => 'शीर्षक या संदेश खोजें';

  @override
  String get announcementShowArchived => 'संग्रहीत भी दिखाएं';

  @override
  String get announcementBannerDismiss => 'यह सूचना बंद करें';

  @override
  String get errorAnnouncementAlreadySent =>
      'यह सूचना पहले ही भेजी जा चुकी है। दोबारा कहने के लिए नई सूचना लिखें।';

  @override
  String get errorAnnouncementNotPublished =>
      'भेजने से पहले इस सूचना को प्रकाशित करें।';

  @override
  String get adminMenu => 'मेन्यू';

  @override
  String get adminMenuOpen => 'मेन्यू खोलें';
}
