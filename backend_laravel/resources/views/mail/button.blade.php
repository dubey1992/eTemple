{{--
    A call to action that survives a mail client.

    A table cell with a background colour rather than a styled <a>, because
    Outlook ignores padding on inline elements. The URL is repeated as text
    underneath: clients that strip links, and readers who do not trust a button
    in an e-mail about their password, both need to see where it goes.
--}}
<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:22px 0;">
    <tr>
        <td align="center" bgcolor="#7A1F3D" style="border-radius:8px;">
            <a href="{{ $url }}"
               style="display:inline-block; padding:12px 26px; font-family:'Noto Sans Devanagari','Nirmala UI','Segoe UI',Arial,sans-serif; font-size:15px; font-weight:700; color:#FFFFFF; text-decoration:none; border-radius:8px;">
                {{ $label }}
            </a>
        </td>
    </tr>
</table>

<div style="font-size:12px; line-height:1.6; color:#6B5B4D; word-break:break-all;">
    यदि बटन काम न करे तो यह पता ब्राउज़र में खोलें / If the button does not work, open this address:<br>
    <span style="color:#7A1F3D;">{{ $url }}</span>
</div>
