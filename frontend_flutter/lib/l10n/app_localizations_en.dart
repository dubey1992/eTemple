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

  @override
  String get navGallery => 'Gallery';

  @override
  String get galleryTitle => 'Photo Gallery';

  @override
  String get gallerySubtitle =>
      'Photos of the temple, worship, festivals and village events will appear here.';

  @override
  String get sectionGallery => 'Photo Gallery';

  @override
  String get viewGallery => 'See the full gallery';

  @override
  String get galleryPhotos => 'Photographs';

  @override
  String get galleryVideos => 'Video darshan';

  @override
  String get galleryAllAlbums => 'All';

  @override
  String get noPhotos => 'No photographs have been published yet.';

  @override
  String get noVideos => 'No video darshan is available yet.';

  @override
  String get galleryLoadMore => 'Show more';

  @override
  String get imageUnavailable => 'The image could not be loaded';

  @override
  String get actionClose => 'Close';

  @override
  String get openInYoutube => 'Watch on YouTube';

  @override
  String get videoDarshanNotice =>
      'Videos are hosted on YouTube; playing one is subject to their terms.';

  @override
  String get navMedia => 'Gallery and video';

  @override
  String get navMediaDesc =>
      'Upload, publish and arrange photographs and videos';

  @override
  String get mediaAdminTitle => 'Gallery and video';

  @override
  String get mediaAdminSubtitle =>
      'Upload photographs and add video links here. Location and camera data is removed from every uploaded photograph automatically.';

  @override
  String get mediaEmpty => 'No media has been added yet.';

  @override
  String get mediaNew => 'Add media';

  @override
  String get mediaEdit => 'Edit media';

  @override
  String get mediaUploadPhoto => 'Upload a photograph';

  @override
  String get mediaAddVideo => 'Add a video link';

  @override
  String get mediaChooseFile => 'Choose a file';

  @override
  String mediaFileHint(int size) {
    return 'JPEG, PNG or WebP · up to $size MB';
  }

  @override
  String get mediaNoFileChosen => 'No file chosen';

  @override
  String mediaFileSelected(String name, String size) {
    return '$name · $size';
  }

  @override
  String get mediaFileRequired => 'Choose a photograph to upload.';

  @override
  String get mediaChooserUnavailable =>
      'Choosing a file is only available in a browser.';

  @override
  String get mediaTypePhoto => 'Photograph';

  @override
  String get mediaTypeVideo => 'Video';

  @override
  String get mediaDelete => 'Remove media';

  @override
  String get mediaDeleteConfirmTitle => 'Remove this media?';

  @override
  String get mediaDeleteConfirmBody =>
      'The file is erased permanently. To hide it instead, unpublish it.';

  @override
  String get mediaDeleted => 'Media removed.';

  @override
  String get mediaInUseTitle => 'This file is still in use';

  @override
  String get mediaInUseBody =>
      'It can only be deleted once it is removed from the items below. Until then it can be unpublished.';

  @override
  String get mediaReferenceEventPoster => 'Event poster';

  @override
  String get mediaReferenceCommitteeMember => 'Committee member';

  @override
  String get mediaReferenceTempleLogo => 'Temple logo';

  @override
  String get mediaReferenceAlbumCover => 'Album cover';

  @override
  String get mediaReferencePage => 'Page';

  @override
  String get mediaMoveUp => 'Move up';

  @override
  String get mediaMoveDown => 'Move down';

  @override
  String get mediaOrderSaved => 'Order saved.';

  @override
  String get fieldCaptionHindi => 'Caption (Hindi)';

  @override
  String get fieldCaptionEnglish => 'Caption (English)';

  @override
  String get fieldVideoUrl => 'YouTube link';

  @override
  String get videoUrlHint => 'Only YouTube links can be added.';

  @override
  String get navAlbums => 'Albums';

  @override
  String get navAlbumsDesc => 'Group photographs by festival or occasion';

  @override
  String get albumsAdminTitle => 'Albums';

  @override
  String get albumsAdminSubtitle =>
      'Group photographs by festival or occasion. Removing an album keeps its photographs.';

  @override
  String get albumsEmpty => 'No albums have been created yet.';

  @override
  String get albumNew => 'New album';

  @override
  String get albumEdit => 'Edit album';

  @override
  String get albumDelete => 'Remove album';

  @override
  String get albumDeleteConfirmTitle => 'Remove this album?';

  @override
  String get albumDeleteConfirmBody =>
      'The album is removed; its photographs are kept.';

  @override
  String get albumDeleted => 'Album removed.';

  @override
  String get albumNone => 'Not in an album';

  @override
  String albumItemCount(int count) {
    return '$count photographs';
  }

  @override
  String get fieldAlbum => 'Album';

  @override
  String get fieldSlug => 'URL name';

  @override
  String get slugHint => 'Generated automatically when left blank.';

  @override
  String get fieldDescriptionHindi => 'Description (Hindi)';

  @override
  String get fieldDescriptionEnglish => 'Description (English)';

  @override
  String get fieldCoverPhoto => 'Cover photograph';

  @override
  String get mediaPickerChoose => 'Choose from the gallery';

  @override
  String get mediaPickerClear => 'Clear';

  @override
  String get mediaPickerEmpty =>
      'There are no published photographs in the gallery yet.';

  @override
  String get mediaPickerHint =>
      'Choose from the gallery, or type an external URL below.';

  @override
  String get navDonate => 'Donate';

  @override
  String get donateTitle => 'Support / Donation';

  @override
  String get donateSubtitle =>
      'Your contribution supports worship arrangements, maintenance, festivals and community service.';

  @override
  String get donateHeading => 'Transparent Community Donation System';

  @override
  String get donateComingSoon => 'Donation details will be added here shortly.';

  @override
  String get donateAction => 'Donate';

  @override
  String get viewDonate => 'See donation details';

  @override
  String get fieldUpiId => 'UPI ID';

  @override
  String get fieldBankName => 'Bank';

  @override
  String get fieldAccountName => 'Account name';

  @override
  String get fieldAccountNumber => 'A/C No.';

  @override
  String get fieldIfsc => 'IFSC';

  @override
  String get donateQrLabel => 'UPI QR';

  @override
  String donateCopied(String label) {
    return '$label copied.';
  }

  @override
  String get actionCopy => 'Copy';

  @override
  String get navDonations => 'Donations and receipts';

  @override
  String get navDonationsDesc =>
      'Record donations, verify them and issue receipts';

  @override
  String get donationsAdminTitle => 'Donations and receipts';

  @override
  String get donationsAdminSubtitle =>
      'Record donations here. A receipt number is issued once a donation is verified, and its details cannot be changed after that.';

  @override
  String get donationsEmpty => 'No donations have been recorded yet.';

  @override
  String get donationNew => 'Record a donation';

  @override
  String get donationEdit => 'Donation';

  @override
  String get donationSearchHint => 'Search a name, receipt number or reference';

  @override
  String get summaryReceived => 'Total received';

  @override
  String get summaryPending => 'Awaiting verification';

  @override
  String get summaryDonors => 'Donors';

  @override
  String get summaryReversed => 'Reversed';

  @override
  String get statusPending => 'Awaiting verification';

  @override
  String get statusReversed => 'Reversed';

  @override
  String get statusConfirmed => 'Verified';

  @override
  String get fieldDonorName => 'Donor name';

  @override
  String get fieldDonorPhone => 'Phone';

  @override
  String get fieldDonorAddress => 'Address';

  @override
  String get fieldAmount => 'Amount (₹)';

  @override
  String get amountHint => 'For example 501 or 501.50';

  @override
  String get fieldDonationDate => 'Date of the donation';

  @override
  String get fieldPaymentMode => 'Payment mode';

  @override
  String get fieldReferenceNumber => 'Reference number';

  @override
  String get referenceHint =>
      'Required for everything but cash — the UPI reference, cheque number or transfer id.';

  @override
  String get fieldPurpose => 'Purpose';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldAnonymous => 'Do not name this donor publicly';

  @override
  String get anonymousHint =>
      'The receipt still names them: it is their own receipt.';

  @override
  String get modeCash => 'Cash';

  @override
  String get modeUpi => 'UPI';

  @override
  String get modeBankTransfer => 'Bank transfer';

  @override
  String get modeCheque => 'Cheque';

  @override
  String get modeCard => 'Card';

  @override
  String get modeOther => 'Other';

  @override
  String get purposeGeneral => 'General';

  @override
  String get purposePuja => 'Worship arrangements';

  @override
  String get purposeMaintenance => 'Maintenance';

  @override
  String get purposeFestival => 'Festival';

  @override
  String get purposeAnnadan => 'Community meals';

  @override
  String get purposeConstruction => 'Construction';

  @override
  String get purposeOther => 'Other';

  @override
  String get fieldReceiptNumber => 'Receipt number';

  @override
  String get receiptNotIssued => 'Issued once verified';

  @override
  String get donationConfirm => 'Verify';

  @override
  String get donationConfirmTitle => 'Verify this donation?';

  @override
  String get donationConfirmBody =>
      'Verifying issues a receipt number. After that the amount, the date and the donor cannot be changed.';

  @override
  String donationConfirmed(String receipt) {
    return 'Verified. Receipt $receipt issued.';
  }

  @override
  String get donationReverse => 'Reverse this donation';

  @override
  String get donationReverseTitle => 'Reverse this donation?';

  @override
  String get donationReverseBody =>
      'The entry is not deleted: it stays, with its receipt number, and stops counting towards every total. A reason is required.';

  @override
  String get fieldReversalReason => 'Reason for reversing';

  @override
  String get donationReversed => 'Donation reversed.';

  @override
  String get donationRecorded => 'Donation recorded.';

  @override
  String get donationPrintReceipt => 'Print the receipt';

  @override
  String get donationLockedNotice =>
      'A receipt has been issued, so only the notes can be changed now. To correct it, reverse it and record it again.';

  @override
  String donationReversedNotice(String date, String reason) {
    return 'Reversed on $date: $reason';
  }

  @override
  String get recordedByLabel => 'Recorded by';

  @override
  String get confirmedByLabel => 'Verified by';

  @override
  String get navDonationSettings => 'Donation details';

  @override
  String get navDonationSettingsDesc =>
      'The UPI, bank details and QR shown on the website';

  @override
  String get donationSettingsTitle => 'Donation details';

  @override
  String get donationSettingsSubtitle =>
      'These appear in the donation section of the website. The account number is shown exactly as typed here — mask it yourself if you want it masked.';

  @override
  String get donationSettingsSaved => 'Donation details saved.';

  @override
  String get fieldQrImage => 'UPI QR image';

  @override
  String get fieldDonateIntroHindi => 'Introduction (Hindi)';

  @override
  String get fieldDonateIntroEnglish => 'Introduction (English)';

  @override
  String get fieldDonateNoteHindi => 'Note (Hindi)';

  @override
  String get fieldDonateNoteEnglish => 'Note (English)';

  @override
  String get fieldPublishDonationDetails => 'Show on the public website';

  @override
  String get donationSettingsIncomplete =>
      'Published, but nothing payable has been filled in — so nothing appears on the website.';

  @override
  String get mediaReferenceDonationQr => 'Donation QR code';

  @override
  String get errorDonationLocked => 'This entry can no longer be changed.';

  @override
  String paginationPage(int current, int last) {
    return 'Page $current of $last';
  }

  @override
  String get actionPrevious => 'Previous';

  @override
  String get actionNext => 'Next';

  @override
  String get contactPageTitle => 'Write to the temple';

  @override
  String get contactPageSubtitle =>
      'Ask about a puja, an event, or anything else. A member of the committee will reply.';

  @override
  String get contactFormTitle => 'Send a message';

  @override
  String get contactOtherWays => 'Other ways to reach us';

  @override
  String get contactOpenForm => 'Write to the committee';

  @override
  String get fieldYourName => 'Your name';

  @override
  String get fieldEnquiryCategory => 'What is it about?';

  @override
  String get fieldEnquiryMessage => 'Your message';

  @override
  String get fieldPreferredLanguage => 'Reply to me in';

  @override
  String get contactChannelHint =>
      'Give a mobile number or an e-mail address, so the committee can reply.';

  @override
  String get actionSendMessage => 'Send message';

  @override
  String get actionSendAnother => 'Send another message';

  @override
  String get enquirySentTitle => 'Your message has been sent';

  @override
  String get enquirySentBody =>
      'A member of the committee will be in touch. Please keep this reference — it is how the temple will find your message.';

  @override
  String get enquiryReferenceLabel => 'Reference';

  @override
  String get enquiryChallengeLabel => 'One small question before sending';

  @override
  String get fieldChallengeAnswer => 'Your answer';

  @override
  String get enquiryCategoryGeneral => 'General enquiry';

  @override
  String get enquiryCategoryPujaBooking => 'Booking a puja';

  @override
  String get enquiryCategoryDonation => 'About donations';

  @override
  String get enquiryCategoryEvent => 'About an event';

  @override
  String get enquiryCategoryVolunteer => 'Volunteering and seva';

  @override
  String get enquiryCategorySuggestion => 'Suggestion';

  @override
  String get enquiryCategoryComplaint => 'Complaint';

  @override
  String get enquiryCategoryOther => 'Something else';

  @override
  String get enquiryStatusNew => 'New';

  @override
  String get enquiryStatusInProgress => 'Being dealt with';

  @override
  String get enquiryStatusResolved => 'Answered';

  @override
  String get enquiryStatusSpam => 'Spam';

  @override
  String get navEnquiries => 'Contact and enquiries';

  @override
  String get navEnquiriesDesc =>
      'Messages devotees have sent, and what has been done about them';

  @override
  String get enquiryInboxTitle => 'Enquiry inbox';

  @override
  String get enquiryInboxSubtitle =>
      'Messages sent through the contact form. Nothing here is ever shown on the public website.';

  @override
  String get enquiryInboxEmpty => 'No messages yet.';

  @override
  String get enquiryDetailTitle => 'Enquiry';

  @override
  String get enquiryAssignedTo => 'Assigned to';

  @override
  String get enquiryUnassigned => 'Not assigned';

  @override
  String get enquiryReplyIn => 'Wants a reply in';

  @override
  String enquiryReceivedOn(String date) {
    return 'Received $date';
  }

  @override
  String enquiryResolvedOn(String date) {
    return 'Answered $date';
  }

  @override
  String enquiryOpenCount(int count) {
    return '$count waiting';
  }

  @override
  String get enquiryStatusUpdated => 'Status updated.';

  @override
  String get enquiryAssignmentUpdated => 'Assignment updated.';

  @override
  String get enquirySearchHint => 'Search a reference, name, number or message';

  @override
  String get enquiryNoReplyChannel => 'No contact details were given';

  @override
  String get enquirySpamNotice =>
      'Marked as spam. It is kept, but out of the inbox.';

  @override
  String get enquiryPrivacyNotice =>
      'These messages are private to the committee.';

  @override
  String get errorEnquiryFormExpired =>
      'This form has expired. Please send your message again.';

  @override
  String get errorEnquiryChallengeRequired =>
      'Please answer the small question shown with the form.';

  @override
  String get enquiryAssignToMe => 'Assign to me';

  @override
  String get enquiryUnassign => 'Remove assignment';

  @override
  String get enquiryChooseMember => 'Give it to a member';

  @override
  String get navAnnouncements => 'Announcements';

  @override
  String get navAnnouncementsDesc =>
      'Notices for the website, and sending them to the committee';

  @override
  String get announcementsTitle => 'Announcements';

  @override
  String get announcementsSubtitle =>
      'What the website is showing, what is scheduled, and what has been sent.';

  @override
  String get announcementsEmpty => 'No announcements yet.';

  @override
  String get announcementNew => 'Write an announcement';

  @override
  String get announcementEdit => 'Edit announcement';

  @override
  String get announcementSaved => 'Announcement saved.';

  @override
  String get announcementPublished =>
      'Published. It is on the website for its scheduled window.';

  @override
  String get announcementArchived =>
      'Archived. It is off the website and has been kept.';

  @override
  String get announcementStatusDraft => 'Draft';

  @override
  String get announcementStatusPublished => 'Published';

  @override
  String get announcementStatusArchived => 'Archived';

  @override
  String get announcementShowingNow => 'On the website now';

  @override
  String announcementScheduledFor(String date) {
    return 'Starts $date';
  }

  @override
  String announcementExpiredOn(String date) {
    return 'Ended $date';
  }

  @override
  String get announcementPriorityNormal => 'Normal';

  @override
  String get announcementPriorityImportant => 'Important';

  @override
  String get announcementPriorityUrgent => 'Urgent';

  @override
  String get fieldAnnouncementTitleHindi => 'Title (Hindi)';

  @override
  String get fieldAnnouncementTitleEnglish => 'Title (English)';

  @override
  String get fieldAnnouncementMessageHindi => 'Message (Hindi)';

  @override
  String get fieldAnnouncementMessageEnglish => 'Message (English)';

  @override
  String get fieldAnnouncementPriority => 'Priority';

  @override
  String get fieldAnnouncementStart => 'Shows from';

  @override
  String get fieldAnnouncementEnd => 'Shows until';

  @override
  String get fieldAnnouncementEndHint =>
      'Leave empty to show it until you archive it';

  @override
  String get fieldAnnouncementLink => 'Read-more link';

  @override
  String get actionPublish2 => 'Publish';

  @override
  String get actionArchive => 'Archive';

  @override
  String get announcementSend => 'Send this announcement';

  @override
  String get announcementSendTitle => 'Send this announcement?';

  @override
  String get announcementSendBody =>
      'Sending puts this notice in the inbox of every active committee account. It cannot be unsent, and it can only be done once.';

  @override
  String get announcementSendConfirm => 'Send it';

  @override
  String announcementSent(int count) {
    return 'Sent to $count committee members.';
  }

  @override
  String announcementSentOn(String date) {
    return 'Sent $date';
  }

  @override
  String get announcementSentNotice =>
      'This announcement has been sent and cannot be sent again.';

  @override
  String get announcementChannels => 'Send by';

  @override
  String get announcementChannelSite => 'Website only';

  @override
  String get announcementChannelEmail => 'E-mail to the committee';

  @override
  String get announcementChannelSms => 'SMS';

  @override
  String get announcementChannelWhatsapp => 'WhatsApp';

  @override
  String get announcementChannelUnavailable => 'Not connected to a provider';

  @override
  String get announcementRecipientsNote =>
      'E-mail goes to committee accounts only. Devotees who wrote to the temple are not on a mailing list.';

  @override
  String get announcementPublishBeforeSending =>
      'Publish this announcement before sending it.';

  @override
  String get announcementSearchHint => 'Search a title or a message';

  @override
  String get announcementShowArchived => 'Show archived';

  @override
  String get announcementBannerDismiss => 'Close this notice';

  @override
  String get errorAnnouncementAlreadySent =>
      'This announcement has already been sent. To say it again, write a new one.';

  @override
  String get errorAnnouncementNotPublished =>
      'Publish this announcement before sending it.';

  @override
  String get adminMenu => 'Menu';

  @override
  String get adminMenuOpen => 'Open the menu';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navAccountsDesc =>
      'Record, check and approve the temple\'s income and expenditure';

  @override
  String get navAccountingCategories => 'Accounting categories';

  @override
  String get navAccountingCategoriesDesc =>
      'The headings every entry in the books is filed under';

  @override
  String get navAccountingSettings => 'Accounting settings';

  @override
  String get navAccountingSettingsDesc =>
      'The opening balance, and whether the books are public';

  @override
  String get navTransparency => 'Accounts';

  @override
  String get transparencyTitle => 'Accounts and transparency';

  @override
  String get transparencySubtitle =>
      'What the temple received, and where it was spent';

  @override
  String get transparencyNotPublishedTitle =>
      'The accounts are not published yet';

  @override
  String get transparencyNotPublishedBody =>
      'The committee has not yet published the temple\'s income and expenditure on this website. Please contact the committee if you would like to know more.';

  @override
  String get transparencySelectYear => 'Choose a financial year';

  @override
  String transparencyYearHeading(String label) {
    return 'Financial year $label';
  }

  @override
  String get transparencyOpeningBalance => 'Balance at the start of the year';

  @override
  String get transparencyDonations => 'Received as donations';

  @override
  String get transparencyOtherIncome => 'Other income';

  @override
  String get transparencyTotalIncome => 'Total received';

  @override
  String get transparencyTotalExpense => 'Total spent';

  @override
  String get transparencyClosingBalance => 'Balance at the end of the year';

  @override
  String get transparencyIncomeBreakdown => 'Where the income came from';

  @override
  String get transparencyExpenseBreakdown => 'Where the money went';

  @override
  String transparencyDonationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count donations',
      one: '1 donation',
      zero: 'No donations recorded this year',
    );
    return '$_temp0';
  }

  @override
  String get transparencyNoIncome =>
      'No income other than donations was recorded this year.';

  @override
  String get transparencyNoExpense => 'No expenditure was recorded this year.';

  @override
  String get transparencyEmptyYear =>
      'Nothing has been recorded for this financial year yet.';

  @override
  String get transparencyOnlyApprovedNote =>
      'These figures include only entries the committee has checked against a bill or a bank statement and approved.';

  @override
  String get transparencyNoNamesNote =>
      'No donor or supplier is named here — only totals and the headings they fall under.';

  @override
  String transparencyAsOf(String date) {
    return 'As at $date';
  }

  @override
  String transparencyOpeningBalanceOn(String date) {
    return 'From $date';
  }

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsSubtitle => 'The temple\'s books';

  @override
  String get accountsNewEntry => 'New entry';

  @override
  String get accountsEditEntry => 'Edit entry';

  @override
  String get accountsTypeIncome => 'Income';

  @override
  String get accountsTypeExpense => 'Expenditure';

  @override
  String get accountsStatusPending => 'To check';

  @override
  String get accountsStatusApproved => 'Approved';

  @override
  String get accountsStatusReversed => 'Reversed';

  @override
  String get accountsAllTypes => 'All';

  @override
  String get accountsAllStatuses => 'All statuses';

  @override
  String get accountsAllCategories => 'All categories';

  @override
  String get accountsApprovedIncome => 'Approved income';

  @override
  String get accountsApprovedExpense => 'Approved expenditure';

  @override
  String get accountsNet => 'Ledger net';

  @override
  String accountsPendingNotCounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count entries are still to be checked, and are counted in no total',
      one: '1 entry is still to be checked, and is counted in no total',
    );
    return '$_temp0';
  }

  @override
  String get accountsEmpty => 'There are no entries yet.';

  @override
  String get accountsEmptyFiltered => 'No entries match this filter.';

  @override
  String get accountsSearchHint =>
      'Search a payee, a description or a reference';

  @override
  String get accountsFieldCategory => 'Category';

  @override
  String get accountsFieldAmount => 'Amount';

  @override
  String get accountsFieldDate => 'Date';

  @override
  String get accountsFieldPaymentMode => 'Payment mode';

  @override
  String get accountsFieldReference => 'Reference number';

  @override
  String get accountsFieldPayee => 'Paid to / received from';

  @override
  String get accountsFieldDescription => 'Description';

  @override
  String get accountsPayeeHelp =>
      'This name is never published on the website.';

  @override
  String get accountsDescriptionHelp =>
      'Your own note for the books. Not published either.';

  @override
  String get accountsBill => 'Bill or receipt';

  @override
  String get accountsAttachBill => 'Attach a bill';

  @override
  String get accountsReplaceBill => 'Replace the bill';

  @override
  String get accountsViewBill => 'View the bill';

  @override
  String get accountsNoBill => 'No bill attached';

  @override
  String get accountsBillHelp =>
      'A photograph or a PDF. Only committee members can open it; it never appears on the website.';

  @override
  String get accountsBillLocked =>
      'The bill on an approved entry cannot be replaced.';

  @override
  String get accountsApprove => 'Approve';

  @override
  String get accountsApproveTitle => 'Approve this entry?';

  @override
  String get accountsApproveBody =>
      'Once approved, this amount counts in every total — including the page the village reads — and nothing but the description can be changed. The only correction after that is to reverse it and record it again.';

  @override
  String get accountsReverse => 'Reverse';

  @override
  String get accountsReverseTitle => 'Reverse this entry?';

  @override
  String get accountsReverseBody =>
      'The row stays in the books, with its bill, and counts in no total. A reason is required — months later it is what explains why this amount was taken out.';

  @override
  String get accountsReverseReason => 'Reason for reversing';

  @override
  String accountsReversedOn(String date) {
    return 'Reversed on $date';
  }

  @override
  String accountsApprovedOn(String date) {
    return 'Approved on $date';
  }

  @override
  String accountsRecordedBy(String name) {
    return 'Recorded by $name';
  }

  @override
  String accountsApprovedBy(String name) {
    return 'Approved by $name';
  }

  @override
  String accountsReversedBy(String name) {
    return 'Reversed by $name';
  }

  @override
  String get accountsLockedNotice =>
      'This entry has been approved and counted in the published totals, so nothing but the description can be changed. To correct it, reverse it and record it again.';

  @override
  String get accountsPendingNotice =>
      'This entry is counted in no total yet. Approve it once you have checked it against the bill or the bank statement.';

  @override
  String get accountsDonationsElsewhere =>
      'Donations are not entered here. They are recorded in the donation register and counted from it.';

  @override
  String get accountsCategoriesTitle => 'Accounting categories';

  @override
  String get accountsCategoriesSubtitle =>
      'The headings every entry in the books is filed under';

  @override
  String get accountsCategoryNew => 'New category';

  @override
  String get accountsCategoryEdit => 'Edit category';

  @override
  String get accountsCategoryNameHi => 'Name (Hindi)';

  @override
  String get accountsCategoryNameEn => 'Name (English)';

  @override
  String get accountsCategoryActive => 'In use';

  @override
  String get accountsCategoryInactive => 'Closed';

  @override
  String accountsCategoryUsage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used by $count entries',
      one: 'Used by 1 entry',
      zero: 'Not used by any entry',
    );
    return '$_temp0';
  }

  @override
  String get accountsCategoryDelete => 'Delete';

  @override
  String get accountsCategoryDeleteTitle => 'Delete this category?';

  @override
  String get accountsCategoryDeleteBody =>
      'Nothing is filed under this heading, so it can be removed.';

  @override
  String get accountsCategoryDeactivate => 'Close it';

  @override
  String get accountsCategoryReactivate => 'Reopen it';

  @override
  String get accountsCategoryInUseNotice =>
      'Entries are filed under this heading, so it can neither be deleted nor moved from income to expenditure — either would change what old entries mean. Close it instead: it stops being offered on new entries, and the old ones still read correctly.';

  @override
  String get accountsCategoryEmpty => 'There are no categories yet.';

  @override
  String get accountsSettingsTitle => 'Accounting settings';

  @override
  String get accountsSettingsSubtitle =>
      'The opening balance, and publishing the books';

  @override
  String get accountsPublishBooks => 'Show the accounts on the website';

  @override
  String get accountsPublishBooksHelp =>
      'Turned on, the website shows the year\'s total income, total expenditure and the breakdown by heading. No donor or supplier is ever named. While it is off, no figure appears on the website at all.';

  @override
  String get accountsBooksArePublic =>
      'The accounts are showing on the website';

  @override
  String get accountsBooksAreNotPublic => 'The accounts are not on the website';

  @override
  String get accountsOpeningBalance => 'Opening balance';

  @override
  String get accountsOpeningBalanceHelp =>
      'What the temple held when the books were started here. Without it the published balance is short by exactly that much. Write a negative amount if the books begin in deficit.';

  @override
  String get accountsOpeningBalanceDate => 'Opening balance date';

  @override
  String get accountsIntroHi => 'Introduction (Hindi)';

  @override
  String get accountsIntroEn => 'Introduction (English)';

  @override
  String get accountsNoteHi => 'Note (Hindi)';

  @override
  String get accountsNoteEn => 'Note (English)';

  @override
  String get accountsIntroHelp =>
      'This sentence appears at the top of the accounts page.';

  @override
  String get errorTransactionLocked =>
      'This entry has already been approved or reversed, so that is no longer possible.';

  @override
  String get errorAccountsNotPublished =>
      'The temple has not published its accounts.';
}
