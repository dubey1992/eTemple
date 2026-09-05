{{--
    "Somebody asked to reset your password."

    Deliberately careful about two things:

    * It never says whether the request came from the reader. It cannot know,
      and telling somebody "you requested this" when they did not is how a
      phishing habit gets taught.
    * It says what to do if it was **not** them, because for an account with
      access to the temple's donation register that is the sentence that
      matters.
--}}
@component('mail.layout', [
    'branding' => $branding,
    'subject' => $subject,
    'footnote' => 'यह एक स्वचालित संदेश है; इस पते पर भेजे गए उत्तर नहीं पढ़े जाते। / This is an automated message; replies to this address are not read.',
])
    <p style="margin:0 0 14px;">नमस्ते {{ $name }},</p>

    <p style="margin:0 0 14px;">
        {{ $branding->templeName }} की वेबसाइट पर आपके खाते का पासवर्ड बदलने का
        अनुरोध प्राप्त हुआ है। नया पासवर्ड बनाने के लिए नीचे दिए गए बटन पर क्लिक करें।
    </p>

    @include('mail.button', ['url' => $url, 'label' => 'नया पासवर्ड बनाएँ / Set a new password'])

    <p style="margin:18px 0 14px; font-size:13px; color:#6B5B4D;">
        यह लिंक {{ $expiresInMinutes }} मिनट तक ही चलेगा। यदि यह अनुरोध आपने नहीं किया है,
        तो कुछ करने की आवश्यकता नहीं — आपका पासवर्ड नहीं बदला जाएगा। यदि आपको लगता है कि
        किसी और ने आपके खाते तक पहुँचने का प्रयास किया है, तो समिति को सूचित करें।
    </p>

    <hr style="border:none; border-top:1px solid #EADFCF; margin:22px 0;">

    <p style="margin:0 0 14px;">Namaste {{ $name }},</p>

    <p style="margin:0 0 14px;">
        A request was made to change the password on your account at
        {{ $branding->templeNameEn }}. Use the button above to set a new one.
    </p>

    <p style="margin:0; font-size:13px; color:#6B5B4D;">
        The link is valid for {{ $expiresInMinutes }} minutes. If you did not
        make this request there is nothing to do — your password will not
        change. If you believe somebody else is trying to reach your account,
        please tell the committee.
    </p>
@endcomponent
