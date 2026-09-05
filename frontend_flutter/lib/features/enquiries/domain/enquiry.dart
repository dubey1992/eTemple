/// The contact form and the committee's inbox (spec Phase 7).
///
/// Two audiences with almost no overlap: a villager who sends one message and
/// is given a reference, and a committee member who reads every message ever
/// sent. The public half deliberately has no model of a stored enquiry at all —
/// there is nothing to model, because nothing is ever read back
/// (PHASE_7_PLAN assumption N1).
library;

/// Status codes, mirroring `App\Models\Enquiry`.
class EnquiryStatuses {
  const EnquiryStatuses._();

  static const String isNew = 'new';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String spam = 'spam';

  /// Inbox order: what needs doing, then what is done, then junk.
  static const List<String> all = [isNew, inProgress, resolved, spam];

  static bool isOpen(String status) => status == isNew || status == inProgress;
}

/// Category codes, mirroring `App\Support\EnquiryCategory`.
class EnquiryCategories {
  const EnquiryCategories._();

  static const String general = 'general';
  static const String pujaBooking = 'puja_booking';
  static const String donation = 'donation';
  static const String event = 'event';
  static const String volunteer = 'volunteer';
  static const String suggestion = 'suggestion';
  static const String complaint = 'complaint';
  static const String other = 'other';

  static const List<String> all = [
    general,
    pujaBooking,
    donation,
    event,
    volunteer,
    suggestion,
    complaint,
    other,
  ];
}

/// The small question the server starts asking once an address has sent enough
/// messages — the specification's "CAPTCHA-after-threshold".
///
/// Both languages arrive together so switching language does not need a new
/// form: the question is the same sum either way.
class EnquiryChallenge {
  const EnquiryChallenge({required this.questionHi, required this.questionEn});

  factory EnquiryChallenge.fromJson(Map<String, Object?> json) =>
      EnquiryChallenge(
        questionHi: json['question_hi'] as String? ?? '',
        questionEn: json['question_en'] as String? ?? '',
      );

  final String questionHi;
  final String questionEn;

  String question(String language) =>
      language == 'en' ? questionEn : questionHi;
}

/// One category as the server names it, with the label it supplied.
class EnquiryCategoryOption {
  const EnquiryCategoryOption({required this.code, required this.label});

  factory EnquiryCategoryOption.fromJson(Map<String, Object?> json) =>
      EnquiryCategoryOption(
        code: json['code'] as String? ?? EnquiryCategories.other,
        label: json['label'] as String? ?? '',
      );

  final String code;

  /// The server's own bilingual label. Used only when this client has not been
  /// taught the code — otherwise the ARB translation wins, because it is in one
  /// language rather than two.
  final String label;
}

/// The ticket the contact form must be submitted with, and everything the
/// server wants the form to know.
class EnquiryForm {
  const EnquiryForm({
    required this.token,
    required this.challenge,
    required this.minFillSeconds,
    required this.expiresInSeconds,
    required this.categories,
    required this.minMessageLength,
    required this.maxMessageLength,
  });

  factory EnquiryForm.fromJson(Map<String, Object?> json) {
    final challenge = json['challenge'];
    final categories = json['categories'];

    return EnquiryForm(
      token: json['token'] as String? ?? '',
      challenge: challenge is Map<String, Object?>
          ? EnquiryChallenge.fromJson(challenge)
          : null,
      minFillSeconds: (json['min_fill_seconds'] as num?)?.toInt() ?? 0,
      expiresInSeconds: (json['expires_in_seconds'] as num?)?.toInt() ?? 3600,
      categories: categories is List
          ? categories
                .whereType<Map<String, Object?>>()
                .map(EnquiryCategoryOption.fromJson)
                .toList(growable: false)
          : const <EnquiryCategoryOption>[],
      minMessageLength: (json['min_message_length'] as num?)?.toInt() ?? 20,
      maxMessageLength: (json['max_message_length'] as num?)?.toInt() ?? 2000,
    );
  }

  final String token;

  /// Null until this address has crossed the threshold.
  final EnquiryChallenge? challenge;

  final int minFillSeconds;
  final int expiresInSeconds;
  final List<EnquiryCategoryOption> categories;
  final int minMessageLength;
  final int maxMessageLength;

  bool get needsChallenge => challenge != null;
}

/// What the visitor typed, on its way to the server.
class EnquiryDraft {
  const EnquiryDraft({
    required this.name,
    required this.category,
    required this.message,
    required this.preferredLanguage,
    required this.formToken,
    this.mobile,
    this.email,
    this.challengeAnswer,
  });

  final String name;
  final String? mobile;
  final String? email;
  final String category;
  final String message;
  final String preferredLanguage;
  final String formToken;
  final String? challengeAnswer;

  Map<String, Object?> toJson() => {
    'name': name,
    'mobile': mobile,
    'email': email,
    'category': category,
    'message': message,
    'preferred_language': preferredLanguage,
    'form_token': formToken,
    'challenge_answer': ?challengeAnswer,
    // The honeypot. Always sent, always empty: a field that only appears when
    // something fills it would be trivial for a script to notice.
    'website': '',
  };
}

/// All the server says back: a reference number and a sentence.
class EnquiryReceipt {
  const EnquiryReceipt({required this.reference, required this.message});

  factory EnquiryReceipt.fromJson(Map<String, Object?> json) => EnquiryReceipt(
    reference: json['reference'] as String?,
    message: json['message'] as String? ?? '',
  );

  /// Null when the submission was silently dropped as spam. The visitor is
  /// never told the difference; only this client knows there is no reference to
  /// show.
  final String? reference;

  final String message;
}

/// One enquiry as the committee sees it. There is no public counterpart.
class Enquiry {
  const Enquiry({
    required this.id,
    required this.reference,
    required this.name,
    required this.category,
    required this.categoryLabel,
    required this.message,
    required this.preferredLanguage,
    required this.status,
    required this.isOpen,
    this.mobile,
    this.email,
    this.assignedTo,
    this.assignedToName,
    this.resolvedAt,
    this.resolvedByName,
    this.acknowledgedAt,
    this.createdAt,
  });

  factory Enquiry.fromJson(Map<String, Object?> json) => Enquiry(
    id: (json['id'] as num?)?.toInt() ?? 0,
    reference: json['reference'] as String? ?? '',
    name: json['name'] as String? ?? '',
    mobile: json['mobile'] as String?,
    email: json['email'] as String?,
    category: json['category'] as String? ?? EnquiryCategories.other,
    categoryLabel: json['category_label'] as String? ?? '',
    message: json['message'] as String? ?? '',
    preferredLanguage: json['preferred_language'] as String? ?? 'hi',
    status: json['status'] as String? ?? EnquiryStatuses.isNew,
    isOpen: json['is_open'] as bool? ?? true,
    assignedTo: (json['assigned_to'] as num?)?.toInt(),
    assignedToName: json['assigned_to_name'] as String?,
    resolvedAt: DateTime.tryParse(json['resolved_at'] as String? ?? ''),
    resolvedByName: json['resolved_by_name'] as String?,
    acknowledgedAt: DateTime.tryParse(json['acknowledged_at'] as String? ?? ''),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  final int id;
  final String reference;
  final String name;
  final String? mobile;
  final String? email;
  final String category;
  final String categoryLabel;
  final String message;

  /// Which language the devotee asked to be answered in — an instruction to
  /// whoever replies, not a display setting (PHASE_7_PLAN assumption N5).
  final String preferredLanguage;

  final String status;
  final bool isOpen;
  final int? assignedTo;
  final String? assignedToName;
  final DateTime? resolvedAt;
  final String? resolvedByName;
  final DateTime? acknowledgedAt;
  final DateTime? createdAt;

  bool get isSpam => status == EnquiryStatuses.spam;
}

/// How many are waiting, by status.
class EnquirySummary {
  const EnquirySummary({
    required this.newCount,
    required this.inProgress,
    required this.resolved,
    required this.spam,
    required this.open,
  });

  factory EnquirySummary.fromJson(Map<String, Object?> json) => EnquirySummary(
    newCount: (json['new'] as num?)?.toInt() ?? 0,
    inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
    resolved: (json['resolved'] as num?)?.toInt() ?? 0,
    spam: (json['spam'] as num?)?.toInt() ?? 0,
    open: (json['open'] as num?)?.toInt() ?? 0,
  );

  static const EnquirySummary empty = EnquirySummary(
    newCount: 0,
    inProgress: 0,
    resolved: 0,
    spam: 0,
    open: 0,
  );

  final int newCount;
  final int inProgress;
  final int resolved;
  final int spam;
  final int open;

  int forStatus(String? status) => switch (status) {
    EnquiryStatuses.isNew => newCount,
    EnquiryStatuses.inProgress => inProgress,
    EnquiryStatuses.resolved => resolved,
    EnquiryStatuses.spam => spam,
    _ => newCount + inProgress + resolved,
  };
}
