<?php

declare(strict_types=1);

namespace App\Support;

/**
 * The vocabulary of the audit log.
 *
 * Codes rather than free text, for the same reason `Permission` is a catalogue:
 * a log whose wording drifts cannot be filtered, and "deleted"/"Deleted"/"remove"
 * in the same column is a log nobody can answer a question from.
 *
 * These are the actions somebody may later be **asked about** — not every write
 * the application performs. Auditing everything produces a table nobody reads
 * and a disk nobody has, on hosting a village temple can afford
 * (PHASE_11_PLAN assumption S1).
 */
final class AuditAction
{
    // --- money -------------------------------------------------------------
    public const DONATION_RECORDED = 'donation.recorded';

    public const DONATION_UPDATED = 'donation.updated';

    public const DONATION_CONFIRMED = 'donation.confirmed';

    public const DONATION_REVERSED = 'donation.reversed';

    public const TRANSACTION_RECORDED = 'transaction.recorded';

    public const TRANSACTION_UPDATED = 'transaction.updated';

    public const TRANSACTION_APPROVED = 'transaction.approved';

    public const TRANSACTION_REVERSED = 'transaction.reversed';

    public const ACCOUNTING_SETTINGS_UPDATED = 'accounting.settings_updated';

    public const DONATION_SETTINGS_UPDATED = 'donation.settings_updated';

    /**
     * A copy of something left the building.
     *
     * Phase 10 could not answer "who took the donor register, and when". This
     * is the row that answers it (assumption S2).
     */
    public const REPORT_EXPORTED = 'report.exported';

    // --- people ------------------------------------------------------------
    public const USER_CREATED = 'user.created';

    public const USER_UPDATED = 'user.updated';

    public const USER_DELETED = 'user.deleted';

    public const USER_PASSWORD_RESET_SENT = 'user.password_reset_sent';

    public const ROLE_UPDATED = 'role.updated';

    public const COMMITTEE_MEMBER_CREATED = 'committee.created';

    public const COMMITTEE_MEMBER_UPDATED = 'committee.updated';

    public const COMMITTEE_MEMBER_DELETED = 'committee.deleted';

    // --- villagers' messages -----------------------------------------------
    /**
     * The one *read* that is audited.
     *
     * Opening an enquiry is the only place where reading is itself the
     * sensitive act: it is somebody's telephone number and their complaint.
     */
    public const ENQUIRY_VIEWED = 'enquiry.viewed';

    public const ENQUIRY_UPDATED = 'enquiry.updated';

    // --- what the village reads --------------------------------------------
    public const CONTENT_DELETED = 'content.deleted';

    public const ANNOUNCEMENT_SENT = 'announcement.sent';

    public const TEMPLE_PROFILE_UPDATED = 'temple.profile_updated';

    public const SITE_SETTINGS_UPDATED = 'site.settings_updated';

    // --- the log about the log ---------------------------------------------
    public const AUDIT_PRUNED = 'audit.pruned';

    /** @return list<string> */
    public static function all(): array
    {
        static $all = null;

        if ($all === null) {
            $all = array_values((new \ReflectionClass(self::class))->getConstants());
        }

        return $all;
    }

    public static function exists(string $action): bool
    {
        return in_array($action, self::all(), true);
    }

    /**
     * Bilingual labels, for the same reason `PaymentMode` has them: the server
     * renders these codes in places the Flutter client cannot help — and a
     * treasurer reading the log at an annual meeting should not need one.
     */
    public static function label(string $action): string
    {
        return match ($action) {
            self::DONATION_RECORDED => 'दान दर्ज किया / Donation recorded',
            self::DONATION_UPDATED => 'दान में सुधार / Donation edited',
            self::DONATION_CONFIRMED => 'दान सत्यापित / Donation verified',
            self::DONATION_REVERSED => 'दान निरस्त / Donation reversed',
            self::TRANSACTION_RECORDED => 'प्रविष्टि दर्ज / Entry recorded',
            self::TRANSACTION_UPDATED => 'प्रविष्टि में सुधार / Entry edited',
            self::TRANSACTION_APPROVED => 'प्रविष्टि स्वीकृत / Entry approved',
            self::TRANSACTION_REVERSED => 'प्रविष्टि निरस्त / Entry reversed',
            self::ACCOUNTING_SETTINGS_UPDATED => 'लेखा सेटिंग्स बदलीं / Accounting settings changed',
            self::DONATION_SETTINGS_UPDATED => 'दान विवरण बदले / Donation details changed',
            self::REPORT_EXPORTED => 'रिपोर्ट डाउनलोड की / Report exported',
            self::USER_CREATED => 'खाता बनाया / Account created',
            self::USER_UPDATED => 'खाता बदला / Account changed',
            self::USER_DELETED => 'खाता हटाया / Account deleted',
            self::USER_PASSWORD_RESET_SENT => 'पासवर्ड लिंक भेजा / Password link sent',
            self::ROLE_UPDATED => 'भूमिका बदली / Role changed',
            self::COMMITTEE_MEMBER_CREATED => 'समिति सदस्य जोड़ा / Committee member added',
            self::COMMITTEE_MEMBER_UPDATED => 'समिति सदस्य बदला / Committee member changed',
            self::COMMITTEE_MEMBER_DELETED => 'समिति सदस्य हटाया / Committee member removed',
            self::ENQUIRY_VIEWED => 'पूछताछ देखी / Enquiry opened',
            self::ENQUIRY_UPDATED => 'पूछताछ पर कार्यवाही / Enquiry acted on',
            self::CONTENT_DELETED => 'सामग्री हटाई / Content deleted',
            self::ANNOUNCEMENT_SENT => 'सूचना भेजी / Announcement sent',
            self::TEMPLE_PROFILE_UPDATED => 'मंदिर प्रोफ़ाइल बदली / Temple profile changed',
            self::SITE_SETTINGS_UPDATED => 'साइट सेटिंग्स बदलीं / Site settings changed',
            self::AUDIT_PRUNED => 'पुराने अभिलेख हटाए / Old audit rows pruned',
            default => $action,
        };
    }
}
