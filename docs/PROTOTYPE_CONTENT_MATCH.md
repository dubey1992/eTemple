# Matching the approved prototype, item by item

**Date:** 2026-09-15
**Reference:** `radha-krishna-thakurbari-prototype.html` (the committee's approved design)
**Scope:** the public marketing pages only. No admin screen changes except where a
new field needed an editor.

A content audit of the public site against the approved prototype found 23
differences. This note records what each one was, what was done about it, and —
for the prototype text that was deliberately **not** copied across — why.

## Why some prototype text is deliberately not here

The prototype is a design mock. Several strings in it describe the mock rather
than the temple, and the working agreement forbids shipping invented temple
content or demo data dressed as real:

| Prototype string | Why it is not in the app |
|---|---|
| `temple@upi`, `Demo Bank`, `XXXX XXXX 1234`, `DEMO0001234` | Invented payment details. A donor who acts on them loses money. |
| `₹1,25,500 / ₹42,300 / ₹83,200 / 126` | Invented figures about somebody's finances. The real ones come from the ledger. |
| `* प्रोटोटाइप में डेमो जानकारी दी गई है…` | Describes the mock. |
| `प्रोटोटाइप डैशबोर्ड — वास्तविक आंकड़े एडमिन पैनल से अपडेट किए जा सकते हैं।` | Describes the mock. Replaced with a sentence about the temple. |
| `Google Map यहाँ जोड़ा जाएगा` | Describes the mock. The block is real instead — see item 20. |
| `धन्यवाद! यह प्रोटोटाइप फॉर्म है।` | The contact form is real and says what really happened. |

## The 23 items

| # | Difference | Done |
|---|---|---|
| 1 | Hero had no Donate call to action | `दान करें` is now the primary hero button, `कार्यक्रम देखें` beside it. The two buttons keep Material icons rather than the design's 🙏 and 📅, because every other button in the app has one |
| 2 | Hero eyebrow read `राधे राधे · जय श्री कृष्ण` | Now `✨ राधे राधे • जय श्री कृष्ण` |
| 3 | Hero card had no caption | The temple's name and its village, both from the profile. The design writes `श्री राधा कृष्ण`; the temple's own name is what the CMS holds, and inventing a second one for the card is not this app's business |
| 4 | An extra gold locality line the prototype does not have | Removed; the locality now appears in the hero card, where the prototype puts it |
| 5 | Topbar left had no 🙏 | Restored |
| 6 | Topbar right showed the address **in English on a Hindi page** | The address is now bilingual in the CMS — see below |
| 7 | No notice band | The prototype's notice is seeded as a real announcement, `आज की सूचना`, with both sentences |
| 8 | About heading read `हमारे बारे में` | `मंदिर परिचय` |
| 9 | The three About cards were one paragraph run | Restored as a three-card grid — see below |
| 10 | Events section had no subtitle | Added |
| 11 | Event kind labels | `भंडारा` is now its own kind, `सामुदायिक सेवा`; a featured event carries a `विशेष` chip |
| 12 | Donate block had no intro | Seeded onto `donation_settings.intro_hi/_en` — see below |
| 13 | The four transparency figures were only on `/transparency` | The band is back on the home page, and links to the full page |
| 14 | `उपलब्ध शेष` was nowhere | It is the fourth figure in that band |
| 15 | Committee heading read `प्रबंध समिति` | `मंदिर समिति` on the public site; the admin console keeps `प्रबंध समिति` |
| 16 | Committee section had no subtitle | Added |
| 17 | Contact heading read `पता एवं संपर्क` | `संपर्क एवं स्थान` |
| 18 | Contact section had no subtitle | Added |
| 19 | Address ran together as one line | Five labelled lines: `ग्राम -`, `पंचायत -`, `थाना -`, `जिला -` |
| 20 | No map block | A real one: it opens the configured map link, or a map search for the temple's own address |
| 21 | Footer had no quick links | Added, from the same admin-managed menu as the header |
| 22 | Footer had no copyright line | `© <year> <temple> · <locality>। सर्वाधिकार सुरक्षित।`, with the year read from the clock so the site never claims to be a year old |
| 23 | `ग़ैर-लाभकारी` (with nukta) in five places | `गैर-लाभकारी`, as the committee wrote it |

## The three that needed a decision

### 6 and 19 — the address became bilingual

Showing `Amarpur Pankhoriya, Kurma, Rasulpur Ekchari, Bhagalpur, Bihar, 813204`
in the strip above a Hindi page is not a styling mismatch, it is the wrong
language on the front page of a village temple's website. The address columns
held one value each, and one value cannot be both `अमरपुर पंखोरिया` and
`Amarpur Pankhoriya`.

So the address columns are now bilingual like every other piece of content in
this system: `village_hi`/`village_en` and so on, resolved by the same
`LocalizedText::resolve` with the same documented Hindi fallback. `postal_code`
stays single, because `813204` is `813204` in both.

The public API keeps its shape — the address block is still a flat map of
strings — because the server resolves them. Only the admin editor gained
fields.

### 9 — the About cards

The prototype's three cards (`हमारी विरासत`, `ग्राम सहभागिता`, `सेवा और भक्ति`)
were flattened into one body with `—` separators, which read as a wall of text.

They are restored as a card grid without a schema change and without taking the
content out of the committee's hands: a paragraph of the CMS body shaped
`<emoji> <heading> — <text>` renders as a card. The emoji and the heading are
content, so the committee can add a fourth card or remove one by editing the
About page, and a paragraph that is not shaped that way still renders as a
paragraph. The editor's help text states the convention.

A first-class structured field with its own editor is the better long-term
answer if the committee ever wants per-card images; this is deliberately the
smaller change.

### 12 — the donate intro is seeded, and will not show yet

The intro is now on `donation_settings.intro_hi/_en`, which is where the CMS
keeps it. It stays invisible until the committee fills in a real UPI ID or bank
account, because Phase 6 decided a donation block that cannot be acted on is not
shown — and the prototype's `temple@upi` / `Demo Bank` are exactly what must not
be seeded to make a screenshot look complete.

The prototype's own wording ("यहाँ … जानकारी प्रदर्शित की जा सकती है" — *details
can be displayed here*) describes the mock, so the seeded copy says what the
temple does instead.

## The emoji, and a change that was reverted

The approved design uses emoji as content, and on a first visit they showed as
tofu boxes. Naming `Segoe UI Emoji`, `Apple Color Emoji` and `Noto Color Emoji`
in `AppTypography.fontFallback` looked like the fix and was tried.

It does nothing. CanvasKit does not read the operating system's font list; it
downloads a Noto fallback for glyphs it cannot draw, and that is what makes the
emoji appear a moment later. Loading the site in a completely fresh browser
profile renders them identically with and without those entries, so the change
was reverted rather than left in place looking like the reason it works.

What remains true is that the first visit has a short window of boxes. That is
recorded in the deployment checklist, where somebody deciding whether to keep
the emoji at all can see it.

## What this cost elsewhere

* Two documentation defects were found next door and fixed: the OpenAPI spec
  still advertised the postal address on `PUT /api/admin/site-settings`, which
  Phase 3 moved to the temple profile; and `PUT /api/admin/temple-profile`
  answered `200` to a request carrying the retired `village` field while saving
  nothing. It now answers `422`.
* The admin temple-profile form is longer — sixteen address fields instead of
  nine — so two widget tests had to scroll to reach the save button.
