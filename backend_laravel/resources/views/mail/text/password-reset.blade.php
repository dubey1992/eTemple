नमस्ते {{ $name }},

{{ $branding->templeName }} की वेबसाइट पर आपके खाते का पासवर्ड बदलने का अनुरोध प्राप्त हुआ है। नया पासवर्ड बनाने के लिए यह पता खोलें:

{{ $url }}

यह लिंक {{ $expiresInMinutes }} मिनट तक ही चलेगा। यदि यह अनुरोध आपने नहीं किया है, तो कुछ करने की आवश्यकता नहीं — आपका पासवर्ड नहीं बदला जाएगा। यदि आपको लगता है कि किसी और ने आपके खाते तक पहुँचने का प्रयास किया है, तो समिति को सूचित करें।

---

Namaste {{ $name }},

A request was made to change the password on your account at {{ $branding->templeNameEn }}. Open the address above to set a new one.

The link is valid for {{ $expiresInMinutes }} minutes. If you did not make this request there is nothing to do — your password will not change. If you believe somebody else is trying to reach your account, please tell the committee.

@include('mail.text.signature', ['branding' => $branding])
यह एक स्वचालित संदेश है; इस पते पर भेजे गए उत्तर नहीं पढ़े जाते।
This is an automated message; replies to this address are not read.
