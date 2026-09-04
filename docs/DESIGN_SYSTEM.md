# Design System — "Maroon & Gold"

The approved prototype (`radha-krishna-thakurbari-prototype.html`) is the
reference for the site's look. This records how its CSS variables map onto the
Flutter theme, so a future change is made in one place and reaches every screen.

Everything below lives in `frontend_flutter/lib/app/theme/`. **No screen may
hard-code a colour, radius or spacing value** — they read `Theme.of(context)` or
the `AppColors` / `AppSpacing` tokens. That rule is why the admin area has now
survived two complete repaints (Marigold & Maroon → Rose & Peacock → Maroon &
Gold) without a single edit inside a feature.

---

## 1. Colour

| Prototype | Token | Value | Role |
|---|---|---|---|
| `--primary` | `AppColors.maroon` | `#8B1E3F` | `colorScheme.primary` |
| `--primary-dark` | `AppColors.maroonDeep` | `#65142D` | Gradient end, brand mark |
| topbar `#38101c` | `AppColors.maroonInk` | `#38101C` | The information strip |
| footer `#2d0d17` | `AppColors.maroonFooter` | `#2D0D17` | Footer ground |
| `--accent` | `AppColors.gold` | `#F4B942` | Hero call to action, ornament |
| — | `AppColors.bronze` | `#A9761A` | `colorScheme.secondary` |
| `--cream` | `AppColors.cream` | `#FFF8EC` | `colorScheme.surface`, page ground |
| alt band `#fffaf2` | `AppColors.creamBand` | `#FFFAF2` | Alternating section band |
| card `#fff` | `AppColors.panel` | `#FFFFFF` | Cards, inputs, chips |
| `border #f1e2d8` | `AppColors.panelBorder` | `#F1E2D8` | `colorScheme.outlineVariant` |
| `--text` | `AppColors.ink` | `#2F2926` | `colorScheme.onSurface` |
| `--muted` | `AppColors.muted` | `#6F655F` | `colorScheme.onSurfaceVariant` |

Two deliberate departures from a literal reading of the prototype:

**Bright gold is a background, never small text.** `#F4B942` on cream fails
contrast at body sizes. `colorScheme.secondary` — which colours icons and small
accent text — is the darkened `bronze` instead. Gold is used at full strength
only on the maroon hero and as a button fill, where it has the contrast for it.

**Status tones are fixed tokens, not scheme roles.** The admin chips used to
draw on `primaryContainer` / `secondaryContainer` / `tertiaryContainer`. When
the palette changed, `ColorScheme.fromSeed` produced *the same colour* for the
first two, and "published" became indistinguishable from the event-type chip.
A status has to read as a status whatever the brand is, so
`positiveSurface` / `warningSurface` / `infoSurface` are named and fixed, and a
test asserts all five chip tones differ.

---

## 2. Shape and spacing

| Prototype | Token | Value |
|---|---|---|
| `--radius: 18px` | `AppRadius.lg` | 18 — cards, panels, list rows |
| buttons, inputs | `AppRadius.md` | 12 |
| chips, pills | `AppRadius.pill` | 999 |
| hero panel | `AppRadius.xl` | 28 |
| `box-shadow` | `AppColors.panelShadow` | `0 10 30 rgba(80,35,25,.12)` |

Cards are white with a hairline border and **no elevation**: on the cream ground
that reads as a lift without a shadow, and it stays crisp on the low-end screens
this site is built for. The prototype's shadow is used on the hero emblem, where
there is no border to do the work.

Every primary action is at least **48dp** tall. This is a village site read on
cheap phones; that is a floor, not a target.

---

## 3. Type

The prototype names `"Noto Sans Devanagari", "Segoe UI", Arial`. The Flutter
theme carries that as a **fallback list**, not as a bundled font: where a reader
has the font the page matches the design, and where they do not, nothing has to
be downloaded before the site is readable. That trade is deliberate — the
connections this site serves are the reason.

Hindi glyph clusters are taller than Latin, so body text uses a 1.55 line height
and headings 1.25, which keeps matras from clipping at the same nominal size.

> **Test note.** CI runners have no Devanagari font at all, so Devanagari text
> renders at close to zero width there. A test must therefore never `tap()` a
> `find.text()` of a translated string — the finder's box is only as wide as the
> glyphs actually draw, and the tap lands outside the widget. Tap an icon or a
> key instead. This cost a red build to learn.

---

## 4. Layout

The public pages are built from **full-width bands** (`SectionBand`), alternating
between `cream` and `creamBand` so each section reads as its own block on a long
scroll. The colour runs edge to edge while `PageContainer` keeps the content
within a 1120px reading measure.

`PageContainer` shrink-wraps vertically. It did not, once, and the footer in
`bottomNavigationBar` expanded to cover the whole page — the site looked correct
and nothing was clickable. There is a regression test.

Breakpoints: mobile < 600, tablet < 1024, desktop ≥ 1024. The information strip
and the horizontal menu are desktop/tablet only; on a phone the menu moves into
a drawer and the strip is dropped rather than wrapped.

---

## 5. What is *not* in the theme

The prototype includes a **donation section** with UPI and bank details, and an
**income/expense transparency dashboard**. Both are deliberately absent: they are
Phases 6 and 9. A gold "Donate" call to action that led nowhere would be worse
than none, so the hero offers the two destinations that exist — the calendar and
the committee.

The prototype's **photo gallery** arrived in Phase 5 and is described below.

---

## 6. The gallery mosaic

The prototype's gallery is a CSS grid — `2fr 1fr 1fr`, 180-pixel rows, the first
child spanning two rows — and `GalleryMosaic` rebuilds exactly that rather than
approximating it with a uniform grid. The uneven rhythm is what makes the block
read as a gallery instead of a contact sheet.

It narrows the way the prototype's own media queries do: two columns on a
tablet, one on a phone, and the feature tile stops spanning once there is no
second row beside it.

**The empty state is the prototype, unchanged.** With nothing published the
block renders the design's five emoji tiles on their gold gradient, under the
caption that says the photographs "will appear here" — which is what that design
already is. Seeding five invented photographs so a demo looks full would put
fabricated temple content in the database.

Every tile requests the 480-pixel variant and passes `cacheWidth`, so the
decoded bitmap matches the size on screen rather than the size of the file. A
1920-pixel image in a 300-pixel tile costs about 15 MB of RAM; twenty of those
is the end of the page on a village phone.
