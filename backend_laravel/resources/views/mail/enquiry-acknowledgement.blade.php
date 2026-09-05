{{--
    "We have your message."

    Not one word the visitor typed appears here — not their name, not their
    message, not their subject line. The address this is sent to was supplied by
    whoever filled the form and need not be theirs: echoing their words would
    let a stranger send chosen text from the temple's own domain to somebody
    else. Everything below is either fixed, or a label from a catalogue the
    committee controls (PHASE_7_PLAN N3).
--}}
@component('mail.layout', [
    'branding' => $branding,
    'subject' => $subject,
    'footnote' => 'यह एक स्वचालित सूचना है; इस पते पर भेजे गए उत्तर नहीं पढ़े जाते। / This is an automated acknowledgement; replies to this address are not read.',
])
    <p style="margin:0 0 14px;">नमस्ते,</p>

    <p style="margin:0 0 14px;">
        {{ $branding->templeName }} को भेजा गया आपका संदेश हमें प्राप्त हो गया है।
        समिति के सदस्य शीघ्र ही आपसे संपर्क करेंगे।
    </p>

    <table role="presentation" cellpadding="0" cellspacing="0" border="0"
           style="width:100%; background-color:#F7EFE2; border-radius:8px; margin:18px 0;">
        <tr>
            <td style="padding:14px 16px; font-size:14px; line-height:1.8;">
                <strong>संदर्भ संख्या / Reference:</strong> {{ $reference }}<br>
                <strong>विषय / Subject:</strong> {{ $category }}
            </td>
        </tr>
    </table>

    <p style="margin:0 0 14px; font-size:13px; color:#6B5B4D;">
        मंदिर से दूरभाष पर संपर्क करते समय कृपया यह संदर्भ संख्या बताएँ।
    </p>

    <hr style="border:none; border-top:1px solid #EADFCF; margin:22px 0;">

    <p style="margin:0 0 14px;">Namaste,</p>

    <p style="margin:0 0 14px;">
        Your message to {{ $branding->templeNameEn }} has reached us. A member of
        the committee will be in touch shortly.
    </p>

    <p style="margin:0; font-size:13px; color:#6B5B4D;">
        Please quote the reference above if you telephone the temple.
    </p>
@endcomponent
