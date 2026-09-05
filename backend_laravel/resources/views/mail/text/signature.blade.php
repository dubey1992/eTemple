--
{{ $branding->templeName }}
@if ($branding->address){{ $branding->address }}
@endif
@if ($branding->phone)दूरभाष / Phone: {{ $branding->phone }}
@endif
@if ($branding->email)ईमेल / E-mail: {{ $branding->email }}
@endif
@if ($branding->siteUrl){{ $branding->siteUrl }}
@endif
