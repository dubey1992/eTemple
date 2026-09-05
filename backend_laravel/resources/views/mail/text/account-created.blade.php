नमस्ते {{ $name }},

{{ $branding->templeName }} की वेबसाइट के प्रबंधन के लिए आपका खाता बना दिया गया है। आरंभ करने के लिए अपना पासवर्ड बनाएँ।

खाता / Account: {{ $email }}
भूमिका / Role: {{ $role }}

पासवर्ड बनाने के लिए यह पता खोलें:

{{ $url }}

यह लिंक {{ $expiresInMinutes }} मिनट तक ही चलेगा। समय बीत जाने पर साइन-इन पृष्ठ पर “पासवर्ड भूल गए” से नया लिंक मँगाया जा सकता है। यदि आपको इस खाते की अपेक्षा नहीं थी, तो कृपया समिति को सूचित करें और इस संदेश को हटा दें।

---

Namaste {{ $name }},

An account has been created for you to help manage the {{ $branding->templeNameEn }} website. Open the address above to set your password.

The link is valid for {{ $expiresInMinutes }} minutes. After that, use “Forgot password” on the sign-in page to request a new one. If you were not expecting this account, please tell the committee and delete this message.

@include('mail.text.signature', ['branding' => $branding])
यह एक स्वचालित संदेश है; इस पते पर भेजे गए उत्तर नहीं पढ़े जाते।
This is an automated message; replies to this address are not read.
