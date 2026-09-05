{{-- The plain-text alternative. Every message has one: some clients show it,
     some readers prefer it, and a mail with no text part scores worse with
     spam filters — which for a temple's only automated e-mail matters. --}}
नमस्ते,

{{ $branding->templeName }} को भेजा गया आपका संदेश हमें प्राप्त हो गया है। समिति के सदस्य शीघ्र ही आपसे संपर्क करेंगे।

संदर्भ संख्या / Reference: {{ $reference }}
विषय / Subject: {{ $category }}

मंदिर से दूरभाष पर संपर्क करते समय कृपया यह संदर्भ संख्या बताएँ।

---

Namaste,

Your message to {{ $branding->templeNameEn }} has reached us. A member of the committee will be in touch shortly.

Please quote the reference above if you telephone the temple.

@include('mail.text.signature', ['branding' => $branding])
यह एक स्वचालित सूचना है; इस पते पर भेजे गए उत्तर नहीं पढ़े जाते।
This is an automated acknowledgement; replies to this address are not read.
