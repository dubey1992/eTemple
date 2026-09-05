{{--
    "An account has been made for you."

    A separate message from the password reset, because it is a separate event.
    A new committee member who has never had a password used to receive a mail
    saying somebody had requested a *reset* of it — which is confusing at best,
    and at worst reads like the phishing it resembles.

    It names who made the account and what the account may do, so the reader can
    tell a real invitation from a forged one: a stranger cannot know that the
    secretary added them as Treasurer this morning.

    No password is ever sent. The account is created with an unusable random
    hash and the member sets their own (PHASE_2_PLAN assumption C5) — a
    plaintext password in an inbox is a plaintext password forever.
--}}
@component('mail.layout', [
    'branding' => $branding,
    'subject' => $subject,
    'footnote' => 'यह एक स्वचालित संदेश है; इस पते पर भेजे गए उत्तर नहीं पढ़े जाते। / This is an automated message; replies to this address are not read.',
])
    <p style="margin:0 0 14px;">नमस्ते {{ $name }},</p>

    <p style="margin:0 0 14px;">
        {{ $branding->templeName }} की वेबसाइट के प्रबंधन के लिए आपका खाता बना दिया गया है।
        आरंभ करने के लिए अपना पासवर्ड बनाएँ।
    </p>

    <table role="presentation" cellpadding="0" cellspacing="0" border="0"
           style="width:100%; background-color:#F7EFE2; border-radius:8px; margin:18px 0;">
        <tr>
            <td style="padding:14px 16px; font-size:14px; line-height:1.8;">
                <strong>खाता / Account:</strong> {{ $email }}<br>
                <strong>भूमिका / Role:</strong> {{ $role }}
            </td>
        </tr>
    </table>

    @include('mail.button', ['url' => $url, 'label' => 'पासवर्ड बनाएँ / Set your password'])

    <p style="margin:18px 0 14px; font-size:13px; color:#6B5B4D;">
        यह लिंक {{ $expiresInMinutes }} मिनट तक ही चलेगा। समय बीत जाने पर साइन-इन पृष्ठ पर
        “पासवर्ड भूल गए” से नया लिंक मँगाया जा सकता है। यदि आपको इस खाते की अपेक्षा नहीं थी,
        तो कृपया समिति को सूचित करें और इस संदेश को हटा दें।
    </p>

    <hr style="border:none; border-top:1px solid #EADFCF; margin:22px 0;">

    <p style="margin:0 0 14px;">Namaste {{ $name }},</p>

    <p style="margin:0 0 14px;">
        An account has been created for you to help manage the
        {{ $branding->templeNameEn }} website. Set your password to begin.
    </p>

    <p style="margin:0; font-size:13px; color:#6B5B4D;">
        The link is valid for {{ $expiresInMinutes }} minutes. After that, use
        “Forgot password” on the sign-in page to request a new one. If you were
        not expecting this account, please tell the committee and delete this
        message.
    </p>
@endcomponent
