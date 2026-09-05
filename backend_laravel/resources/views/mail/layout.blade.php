{{--
    The shell every e-mail this system sends is wrapped in.

    Design constraints, all of them deliberate:

    * **No images, no web fonts, no external stylesheet.** Most mail clients
      block remote images by default and many strip <style> blocks, so anything
      that matters is inline and made of text. It also means a message costs
      nothing to open on a village connection.
    * **Tables, and inline styles.** Outlook still lays out with tables, and a
      flexbox e-mail is a broken e-mail.
    * **A Devanagari font stack.** The temple writes in Hindi; naming the fonts
      gives clients a chance to pick a good one instead of a default that clips
      matras.
    * **The temple signs it, not the software.** The name, address and contact
      details come from the CMS.
--}}
<!DOCTYPE html>
<html lang="hi">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $subject ?? $branding->templeName }}</title>
</head>
<body style="margin:0; padding:0; background-color:#FBF6EE;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
       style="background-color:#FBF6EE; padding:24px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0"
                   style="width:100%; max-width:600px; background-color:#FFFFFF; border-radius:12px; overflow:hidden; border:1px solid #EADFCF;">

                {{-- The temple's own name across the top, in its own colours. --}}
                <tr>
                    <td style="background-color:#7A1F3D; padding:20px 28px;">
                        <div style="font-family:'Noto Sans Devanagari','Nirmala UI','Segoe UI',Arial,sans-serif; font-size:19px; font-weight:700; color:#F5C96B; line-height:1.4;">
                            {{ $branding->templeName }}
                        </div>
                        @if ($branding->address)
                            <div style="font-family:'Noto Sans Devanagari','Nirmala UI','Segoe UI',Arial,sans-serif; font-size:12px; color:#F0DCC0; padding-top:4px;">
                                {{ $branding->address }}
                            </div>
                        @endif
                    </td>
                </tr>

                <tr>
                    <td style="padding:28px; font-family:'Noto Sans Devanagari','Nirmala UI','Segoe UI',Arial,sans-serif; font-size:15px; line-height:1.7; color:#2E2A26;">
                        {{ $slot }}
                    </td>
                </tr>

                <tr>
                    <td style="background-color:#F7EFE2; padding:18px 28px; font-family:'Noto Sans Devanagari','Nirmala UI','Segoe UI',Arial,sans-serif; font-size:12px; line-height:1.6; color:#6B5B4D;">
                        @if ($branding->phone || $branding->email)
                            <div>
                                @if ($branding->phone) दूरभाष / Phone: {{ $branding->phone }} @endif
                                @if ($branding->phone && $branding->email) &nbsp;·&nbsp; @endif
                                @if ($branding->email) ईमेल / E-mail: {{ $branding->email }} @endif
                            </div>
                        @endif
                        @if ($branding->siteUrl)
                            <div style="padding-top:4px;">{{ $branding->siteUrl }}</div>
                        @endif
                        <div style="padding-top:10px; color:#8A7868;">
                            {{ $footnote ?? 'यह एक स्वचालित संदेश है। / This is an automated message.' }}
                        </div>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
