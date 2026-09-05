import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/localization/message_translations.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_code.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/enquiry_providers.dart';
import '../../domain/enquiry.dart';
import '../enquiry_labels.dart';

/// The contact form itself.
///
/// Three things here are not ordinary form plumbing, and all three are about
/// the fact that anybody at all can post this:
///
///  * a **honeypot** field that is never rendered and is always sent empty —
///    `EnquiryDraft` includes it unconditionally, because a field that appeared
///    only when filled would be trivial for a script to notice;
///  * the **ticket** from the server, fetched when the page opened, which is
///    also how the server knows how long the form was open;
///  * the **question**, which appears only once this address has sent enough
///    messages that the server started asking one.
///
/// When a submission is refused because the ticket went stale, everything the
/// visitor typed stays on screen and a fresh ticket is fetched underneath them.
/// Losing somebody's message to an anti-spam measure would be a worse failure
/// than the spam.
class EnquiryFormCard extends ConsumerStatefulWidget {
  const EnquiryFormCard({
    super.key,
    required this.form,
    required this.onSubmitted,
  });

  final EnquiryForm form;
  final ValueChanged<EnquiryReceipt> onSubmitted;

  @override
  ConsumerState<EnquiryFormCard> createState() => _EnquiryFormCardState();
}

class _EnquiryFormCardState extends ConsumerState<EnquiryFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  final _answer = TextEditingController();

  String _category = EnquiryCategories.general;
  String? _preferredLanguage;
  bool _sending = false;
  AppException? _error;

  /// Set locally when neither contact channel was filled in. Kept separate from
  /// [_error] rather than faked as a server response, so the banner says the one
  /// thing that is actually wrong instead of guessing from field names.
  bool _channelMissing = false;

  @override
  void dispose() {
    // Held for the life of the card, not the life of one build: a controller
    // disposed while its field is still attached is an assertion failure.
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _message.dispose();
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final challenge = widget.form.challenge;

    // Defaults to the language being read, which is right far more often than
    // not — and is only a default (PHASE_7_PLAN assumption N5).
    _preferredLanguage ??= locale == 'en' ? 'en' : 'hi';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_channelMissing || _error != null) ...[
                _ErrorBanner(
                  message: _channelMissing
                      ? l10n.contactChannelHint
                      : _messageFor(_error!, l10n),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              TextFormField(
                key: const Key('enquiry-name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.fieldYourName,
                  errorText: _fieldError('name'),
                ),
                validator: (value) => (value == null || value.trim().length < 2)
                    ? l10n.validationRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Either channel will do, but not neither: the rule is stated
              // once here and enforced again on the server (assumption N6).
              _ContactChannels(
                mobile: TextFormField(
                  key: const Key('enquiry-mobile'),
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: l10n.fieldMobile,
                    errorText: _fieldError('mobile'),
                  ),
                ),
                email: TextFormField(
                  key: const Key('enquiry-email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.fieldEmail,
                    errorText: _fieldError('email'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.contactChannelHint,
                key: const Key('enquiry-channel-hint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                isExpanded: true,
                key: const Key('enquiry-category'),
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: l10n.fieldEnquiryCategory,
                ),
                items: [
                  for (final option in _categories)
                    DropdownMenuItem(
                      value: option.code,
                      child: Text(
                        EnquiryLabels.category(
                          l10n,
                          option.code,
                          fallback: option.label,
                        ),
                      ),
                    ),
                ],
                onChanged: (value) => setState(
                  () => _category = value ?? EnquiryCategories.general,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                key: const Key('enquiry-message'),
                controller: _message,
                maxLines: 5,
                maxLength: widget.form.maxMessageLength,
                decoration: InputDecoration(
                  labelText: l10n.fieldEnquiryMessage,
                  errorText: _fieldError('message'),
                ),
                validator: (value) =>
                    (value == null ||
                        value.trim().length < widget.form.minMessageLength)
                    ? l10n.validationRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                l10n.fieldPreferredLanguage,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<String>(
                key: const Key('enquiry-language'),
                segments: [
                  ButtonSegment(value: 'hi', label: Text(l10n.languageHindi)),
                  ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ],
                selected: {_preferredLanguage!},
                onSelectionChanged: (selection) =>
                    setState(() => _preferredLanguage = selection.first),
              ),

              if (challenge != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.enquiryChallengeLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        challenge.question(locale),
                        key: const Key('enquiry-challenge-question'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        key: const Key('enquiry-challenge-answer'),
                        controller: _answer,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.fieldChallengeAnswer,
                          errorText: _fieldError('challenge_answer'),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? l10n.validationRequired
                            : null,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('enquiry-submit'),
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(l10n.actionSendMessage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The server's list when it sent one, this bundle's otherwise.
  List<EnquiryCategoryOption> get _categories => widget.form.categories.isEmpty
      ? [
          for (final code in EnquiryCategories.all)
            EnquiryCategoryOption(code: code, label: ''),
        ]
      : widget.form.categories;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mobile = _mobile.text.trim();
    final email = _email.text.trim();

    // Checked here so the visitor is told immediately, and again on the server
    // because a client check is never the rule.
    if (mobile.isEmpty && email.isEmpty) {
      setState(() {
        _channelMissing = true;
        _error = null;
      });
      return;
    }

    setState(() {
      _sending = true;
      _channelMissing = false;
      _error = null;
    });

    try {
      final receipt = await ref
          .read(enquiryRepositoryProvider)
          .submit(
            EnquiryDraft(
              name: _name.text.trim(),
              mobile: mobile.isEmpty ? null : mobile,
              email: email.isEmpty ? null : email,
              category: _category,
              message: _message.text.trim(),
              preferredLanguage: _preferredLanguage ?? 'hi',
              formToken: widget.form.token,
              challengeAnswer: _answer.text.trim().isEmpty
                  ? null
                  : _answer.text.trim(),
            ),
          );

      if (!mounted) return;
      widget.onSubmitted(receipt);
    } on AppException catch (error) {
      if (!mounted) return;

      setState(() {
        _sending = false;
        _error = error;
      });

      // A spent or stale ticket is recoverable and common: fetch a fresh one
      // underneath the visitor, who keeps every word they typed and only has
      // to press send again.
      if (error.code == ErrorCode.enquiryFormExpired ||
          error.code == ErrorCode.enquiryChallengeRequired) {
        ref.invalidate(enquiryFormProvider);
      }
    } finally {
      if (mounted && _sending) setState(() => _sending = false);
    }
  }

  String? _fieldError(String field) => _error?.fieldErrors[field]?.firstOrNull;

  String _messageFor(AppException error, AppLocalizations l10n) =>
      switch (error.code) {
        ErrorCode.enquiryFormExpired => l10n.errorEnquiryFormExpired,
        ErrorCode.enquiryChallengeRequired =>
          l10n.errorEnquiryChallengeRequired,
        ErrorCode.validationFailed => l10n.contactChannelHint,
        _ => error.localizedMessage(l10n),
      };
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('enquiry-error'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The two ways of being replied to: side by side when there is room, stacked
/// when there is not.
class _ContactChannels extends StatelessWidget {
  const _ContactChannels({required this.mobile, required this.email});

  final Widget mobile;
  final Widget email;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth > 520
        ? Row(
            children: [
              Expanded(child: mobile),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: email),
            ],
          )
        : Column(
            children: [
              mobile,
              const SizedBox(height: AppSpacing.md),
              email,
            ],
          ),
  );
}
