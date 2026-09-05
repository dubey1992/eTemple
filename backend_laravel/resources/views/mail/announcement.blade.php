{{--
    An announcement, in a committee member's inbox.

    Unlike the enquiry acknowledgement, this one **does** carry the temple's own
    words — that is the whole point of it. The difference is who wrote them: a
    committee member holding `announcements.manage`, not an anonymous stranger.

    It is still escaped. The author is trusted to write the notice; they are not
    trusted to have avoided a `<` by accident, and a mail client will interpret
    markup as readily as a browser. Blade's `{{ }}` does that here.

    Both languages travel in one message: the recipients are the temple's own
    committee, who between them read both, and there is no per-account language
    preference column.
--}}
@component('mail.layout', [
    'branding' => $branding,
    'subject' => $subject,
    'footnote' => 'यह सूचना मंदिर समिति के सदस्यों को भेजी गई है। / This notice was sent to the temple committee.',
])
    <h1 style="margin:0 0 16px; font-size:20px; line-height:1.4; color:#7A1F3D;">
        {{ $announcement->title_hi }}
    </h1>

    <div style="margin:0 0 8px; white-space:pre-wrap;">{{ $announcement->message_hi }}</div>

    @if (filled($announcement->title_en) || filled($announcement->message_en))
        <hr style="border:none; border-top:1px solid #EADFCF; margin:22px 0;">

        <h2 style="margin:0 0 12px; font-size:17px; line-height:1.4; color:#7A1F3D;">
            {{ $announcement->title_en ?? $announcement->title_hi }}
        </h2>

        @if (filled($announcement->message_en))
            <div style="white-space:pre-wrap;">{{ $announcement->message_en }}</div>
        @endif
    @endif

    @if (filled($announcement->link_url))
        @include('mail.button', [
            'url' => $announcement->link_url,
            'label' => 'अधिक जानकारी / Read more',
        ])
    @endif

    <p style="margin:22px 0 0; color:#6B5B4D;">— {{ $branding->templeName }}</p>
@endcomponent
