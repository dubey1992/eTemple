{{ $announcement->title_hi }}

{{ $announcement->message_hi }}
@if (filled($announcement->title_en) || filled($announcement->message_en))

---

{{ $announcement->title_en ?? $announcement->title_hi }}
@if (filled($announcement->message_en))

{{ $announcement->message_en }}
@endif
@endif
@if (filled($announcement->link_url))

अधिक जानकारी / Read more: {{ $announcement->link_url }}
@endif

@include('mail.text.signature', ['branding' => $branding])
यह सूचना मंदिर समिति के सदस्यों को भेजी गई है।
This notice was sent to the temple committee.
