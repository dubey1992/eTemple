// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Radha Krishna Thakurbari';

  @override
  String get invocation => 'Radhe Radhe · Jai Shri Krishna';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageEnglish => 'English';

  @override
  String get switchToEnglish => 'View in English';

  @override
  String get switchToHindi => 'View in Hindi';

  @override
  String get navHome => 'Home';

  @override
  String get navAdmin => 'Administration';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get foundationHeadline => 'The website is being prepared';

  @override
  String get foundationBody =>
      'Temple information, events, photographs and donation details will appear here shortly.';

  @override
  String get foundationNote =>
      'This page shows the technical foundation only. Content is added in the next phase.';

  @override
  String get loginTitle => 'Administration sign in';

  @override
  String get loginSubtitle => 'For committee members only';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get passwordLabel => 'Password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your registered e-mail. If the account is active, a reset link will be sent.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get adminDashboardTitle => 'Administration dashboard';

  @override
  String adminWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get adminFoundationNote =>
      'Administration features are added in the coming phases.';

  @override
  String get roleLabel => 'Role';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmailInvalid => 'Please enter a valid e-mail address';

  @override
  String validationPasswordTooShort(int count) {
    return 'Password must be at least $count characters';
  }

  @override
  String get stateLoading => 'Loading…';

  @override
  String get stateEmpty => 'There is nothing to show yet';

  @override
  String get stateRetry => 'Try again';

  @override
  String get stateUnauthorizedTitle => 'Not permitted';

  @override
  String get stateUnauthorizedBody =>
      'You do not have permission to view this page.';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundBody => 'The page you are looking for is not available.';

  @override
  String get goHome => 'Go to home page';

  @override
  String get errorNetwork =>
      'The network is unavailable. Please check your internet connection.';

  @override
  String get errorTimeout => 'The server did not respond. Please try again.';

  @override
  String get errorInvalidCredentials => 'The e-mail or password is incorrect.';

  @override
  String get errorAccountInactive =>
      'This account is not active. Please contact the committee.';

  @override
  String get errorAccountBlocked =>
      'This account has been blocked. Please contact the committee.';

  @override
  String get errorUnauthenticated => 'Please sign in again.';

  @override
  String get errorForbidden => 'You are not allowed to perform this action.';

  @override
  String get errorNotFound => 'The requested information was not found.';

  @override
  String get errorValidation =>
      'Some of the information provided is not valid.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please reload the page.';

  @override
  String get errorServer => 'A server error occurred. Please try again later.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get navAbout => 'About us';

  @override
  String get navContact => 'Contact';

  @override
  String get heroDarshan => 'Take darshan';

  @override
  String get sectionAbout => 'About us';

  @override
  String get sectionAddress => 'Address and contact';

  @override
  String get sectionReadMore => 'Read more';

  @override
  String get contactPhone => 'Phone';

  @override
  String get contactEmail => 'E-mail';

  @override
  String get contactMap => 'View on map';

  @override
  String get fallbackNotice =>
      'This content is currently available in Hindi only.';

  @override
  String get contentComingSoon => 'This information will be added shortly.';

  @override
  String get addressComingSoon => 'The address will be added shortly.';

  @override
  String get adminContent => 'Content';

  @override
  String get adminPagesTitle => 'Pages';

  @override
  String get adminPagesSubtitle => 'Edit the public website content here.';

  @override
  String get adminEditPage => 'Edit page';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPublished => 'Published';

  @override
  String get fieldTitleHindi => 'Title (Hindi)';

  @override
  String get fieldTitleEnglish => 'Title (English)';

  @override
  String get fieldContentHindi => 'Content (Hindi)';

  @override
  String get fieldContentEnglish => 'Content (English)';

  @override
  String get fieldMetaTitle => 'SEO title';

  @override
  String get fieldMetaDescription => 'SEO description';

  @override
  String get fieldOptional => 'Optional';

  @override
  String get hindiRequiredHint =>
      'Hindi is required. Hindi is shown when English is missing.';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionPublish => 'Publish';

  @override
  String get actionUnpublish => 'Unpublish';

  @override
  String get saveSuccess => 'Changes saved.';

  @override
  String get englishMissingBadge => 'English missing';

  @override
  String get dashboardWelcome => 'Administration dashboard';

  @override
  String get dashboardSubtitle =>
      'The options below reflect what your account is permitted to do.';

  @override
  String get dashboardNoAccess =>
      'Your account has not been granted any administration features yet.';

  @override
  String get navUsers => 'Committee accounts';

  @override
  String get navUsersDesc => 'Create and manage committee member accounts';

  @override
  String get navRoles => 'Roles and permissions';

  @override
  String get navRolesDesc => 'Decide what each role is allowed to do';

  @override
  String get navPagesDesc => 'Edit the public website content';

  @override
  String get navSiteSettings => 'Site settings';

  @override
  String get navSiteSettingsDesc => 'Tagline, address, menu and footer';

  @override
  String get usersTitle => 'Committee accounts';

  @override
  String get usersSubtitle => 'Manage the accounts of committee members here.';

  @override
  String get userNew => 'New account';

  @override
  String get userEdit => 'Edit account';

  @override
  String get userCreate => 'Create account';

  @override
  String get userNeverSignedIn => 'Never signed in';

  @override
  String get userLastLogin => 'Last sign-in';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get fieldMobile => 'Mobile';

  @override
  String get fieldRole => 'Role';

  @override
  String get fieldStatus => 'Status';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get userPasswordHint =>
      'The new member sets their own password using a link sent to their e-mail.';

  @override
  String get userSendReset => 'Send password link';

  @override
  String get userResetSent => 'Password link sent.';

  @override
  String get userCreated =>
      'Account created and a password link has been sent.';

  @override
  String get rolesTitle => 'Roles and permissions';

  @override
  String get rolesSubtitle => 'Which modules each role can reach.';

  @override
  String roleMembers(int count) {
    return '$count accounts';
  }

  @override
  String rolePermissionCount(int count) {
    return '$count permissions';
  }

  @override
  String get roleFixed => 'Super Admin always holds every permission.';

  @override
  String get rolePermissionsTitle => 'Permissions';

  @override
  String get permissionsSaved => 'Permissions saved.';

  @override
  String modulePhasePending(int phase) {
    return 'Available in phase $phase';
  }

  @override
  String get loginHistoryTitle => 'Sign-in history';

  @override
  String get loginHistoryEmpty => 'No sign-ins recorded yet.';

  @override
  String get loginSuccess => 'Successful';

  @override
  String get loginFailed => 'Failed';

  @override
  String get resetPasswordTitle => 'Set a new password';

  @override
  String get resetPasswordSubtitle => 'Enter a new password for your account.';

  @override
  String get fieldNewPassword => 'New password';

  @override
  String get fieldConfirmPassword => 'Repeat the password';

  @override
  String get passwordsDoNotMatch => 'The two passwords do not match';

  @override
  String get resetPasswordDone =>
      'Your password has been changed. Please sign in.';

  @override
  String get resetLinkInvalid => 'This link is invalid or has expired.';

  @override
  String get siteSettingsTitle => 'Site settings';

  @override
  String get siteSettingsSubtitle => 'Home page tagline, address and footer.';

  @override
  String get fieldTagline => 'Tagline';

  @override
  String get fieldFooter => 'Footer line';

  @override
  String get fieldVillage => 'Village';

  @override
  String get fieldPanchayat => 'Panchayat';

  @override
  String get fieldPoliceStation => 'Police station';

  @override
  String get fieldDistrict => 'District';

  @override
  String get fieldState => 'State';

  @override
  String get fieldPostalCode => 'Postal code';

  @override
  String get fieldContactPhone => 'Contact phone';

  @override
  String get fieldContactEmail => 'Contact e-mail';

  @override
  String get navTempleProfile => 'Temple profile';

  @override
  String get navTempleProfileDesc =>
      'The temple\'s name, address, history and mission';

  @override
  String get navCommittee => 'Management committee';

  @override
  String get navCommitteeDesc => 'Members, tenure and public visibility';

  @override
  String get sectionCommittee => 'Management committee';

  @override
  String get sectionHistory => 'History of the temple';

  @override
  String get sectionMission => 'Our mission';

  @override
  String get committeeTitle => 'Management committee';

  @override
  String get committeeSubtitle => 'The members who look after the temple.';

  @override
  String get committeeComingSoon =>
      'Details of the committee will be added shortly.';

  @override
  String get viewCommittee => 'See the full committee';

  @override
  String get panchayatLabel => 'Panchayat';

  @override
  String establishedIn(int year) {
    return 'Established $year';
  }

  @override
  String tenureSince(String from) {
    return 'Serving since $from';
  }

  @override
  String tenureRange(String from, String to) {
    return 'Tenure: $from – $to';
  }

  @override
  String get sectionContact => 'Contact details';

  @override
  String get addressLivesInTempleProfile =>
      'The address now lives in the temple profile, so it is kept in one place only.';

  @override
  String get templeProfileTitle => 'Temple profile';

  @override
  String get templeProfileSubtitle =>
      'The temple\'s name, address and introduction. This name appears at the top of the website.';

  @override
  String get sectionIdentity => 'Identity';

  @override
  String get fieldTempleName => 'Temple name';

  @override
  String get fieldHistory => 'History';

  @override
  String get fieldMission => 'Mission';

  @override
  String get fieldAddressLine1 => 'Address line 1';

  @override
  String get fieldAddressLine2 => 'Address line 2';

  @override
  String get fieldCountry => 'Country';

  @override
  String get fieldLogoUrl => 'Logo URL';

  @override
  String get fieldMapUrl => 'Map URL';

  @override
  String get fieldEstablishedYear => 'Year established';

  @override
  String get templeNameHint =>
      'This name is used in the site title, header and footer. While it is blank the app\'s default name is shown.';

  @override
  String get committeeAdminTitle => 'Management committee';

  @override
  String get committeeAdminSubtitle =>
      'Add committee members and decide which of their details are public.';

  @override
  String get committeeEmpty => 'No members have been added yet.';

  @override
  String get memberNew => 'New member';

  @override
  String get memberEdit => 'Edit member';

  @override
  String get memberCreate => 'Add member';

  @override
  String get memberCreated => 'Member added.';

  @override
  String get memberDeleted => 'Member removed.';

  @override
  String get memberDelete => 'Remove member';

  @override
  String get memberDeleteConfirmTitle => 'Remove this member?';

  @override
  String get memberDeleteConfirmBody =>
      'This erases the record permanently. If the term has simply ended, set the tenure end date instead and the record is kept.';

  @override
  String get memberTenureEnded => 'Tenure ended';

  @override
  String get memberNotPublished => 'Not published';

  @override
  String get actionDelete => 'Remove';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldDesignation => 'Designation';

  @override
  String get fieldBio => 'Short introduction';

  @override
  String get fieldPhone => 'Phone';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPhotoUrl => 'Photo URL';

  @override
  String get fieldTenureStart => 'Tenure start';

  @override
  String get fieldTenureEnd => 'Tenure end';

  @override
  String get fieldSortOrder => 'Display order';

  @override
  String get fieldPublished => 'Show on the public website';

  @override
  String get dateHint => 'YYYY-MM-DD';

  @override
  String get consentTitle => 'Consent for personal details';

  @override
  String get consentExplain =>
      'Phone, e-mail and photograph are published only while the member’s consent is on record. Withdrawing consent hides all three immediately.';

  @override
  String get consentRecorded => 'The member\'s consent is on record';

  @override
  String consentRecordedOn(String date) {
    return 'Consent recorded on $date';
  }

  @override
  String get consentMissingHint =>
      'No personal detail can be published until consent is recorded.';

  @override
  String get showPhonePublicly => 'Show the phone number publicly';

  @override
  String get showEmailPublicly => 'Show the e-mail address publicly';

  @override
  String get showPhotoPublicly => 'Show the photograph publicly';

  @override
  String get consentPublicWarning => 'Personal details are public';

  @override
  String get sectionTenure => 'Tenure';

  @override
  String get actionBack => 'Back';

  @override
  String get valueNotAvailable => 'NA';

  @override
  String get navEvents => 'Puja and events';

  @override
  String get navEventsDesc =>
      'Aarti, bhajan-kirtan, festivals and the calendar';

  @override
  String get eventsTitle => 'Puja and events';

  @override
  String get eventsSubtitle =>
      'Daily aarti, weekly kirtan and the festivals ahead.';

  @override
  String get sectionEvents => 'Coming up';

  @override
  String get viewUpcoming => 'Upcoming';

  @override
  String get viewPast => 'Past';

  @override
  String get noUpcomingEvents => 'No events are scheduled yet.';

  @override
  String get noPastEvents => 'No past events are recorded yet.';

  @override
  String get viewAllEvents => 'See all events';

  @override
  String get eventCancelled => 'Cancelled';

  @override
  String get eventCancelledNotice => 'This event has been cancelled.';

  @override
  String get eventVenue => 'Venue';

  @override
  String get eventUpcomingDates => 'Coming up on';

  @override
  String get eventNotFound => 'This event is not available.';

  @override
  String get eventTypeAarti => 'Aarti';

  @override
  String get eventTypeBhajanKirtan => 'Bhajan-kirtan';

  @override
  String get eventTypeFestival => 'Festival';

  @override
  String get eventTypePuja => 'Puja';

  @override
  String get eventTypeOther => 'Other';

  @override
  String get recurrenceNone => 'Once';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get eventsAdminTitle => 'Puja and events';

  @override
  String get eventsAdminSubtitle =>
      'Add aarti, kirtan and festivals here. A repeating event is entered once.';

  @override
  String get eventsEmpty => 'No events have been added yet.';

  @override
  String get eventNew => 'New event';

  @override
  String get eventEdit => 'Edit event';

  @override
  String get eventCreate => 'Add event';

  @override
  String get eventCreated => 'Event added.';

  @override
  String get eventDeleted => 'Event removed.';

  @override
  String get eventDelete => 'Remove event';

  @override
  String get eventDeleteConfirmTitle => 'Remove this event?';

  @override
  String get eventDeleteConfirmBody =>
      'This erases the record permanently. If the event is merely called off, set its status to Cancelled instead so devotees are told.';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get filterAll => 'All';

  @override
  String get fieldEventType => 'Event type';

  @override
  String get fieldEventTitle => 'Event name';

  @override
  String get fieldEventDescription => 'Description';

  @override
  String get fieldVenue => 'Venue';

  @override
  String get fieldStartAt => 'Starts';

  @override
  String get fieldEndAt => 'Ends';

  @override
  String get fieldRecurrence => 'Repeats';

  @override
  String get fieldRecurrenceDays => 'On which days';

  @override
  String get fieldRecurrenceUntil => 'Repeat until';

  @override
  String get fieldPosterUrl => 'Poster URL';

  @override
  String get fieldFeatured => 'Show on the home page';

  @override
  String get recurringHint =>
      'A repeating event is stored once — the daily aarti does not need 365 entries.';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get pickTime => 'Pick a time';

  @override
  String get clearEndTime => 'Clear the end time';

  @override
  String get viewEvents => 'View Events';
}
