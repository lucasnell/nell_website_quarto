# Design notes

The brief was two reference sites rather than a spec:

- <https://labs.ala.org.au> — Atlas of Living Australia's lab site
- <https://nbdev.fast.ai>

Both are themselves Quarto builds, which is partly why Quarto was chosen: the
look is reachable through SCSS variables rather than custom templates.

What they share, and what was taken from them: confident large type, generous
whitespace, sans-serif throughout, a single strong accent. ALA Labs adds
saturated field imagery at full bleed, which suits a field ecologist — the
homepage hero (a Mývatn sunset, with the name/tagline overlaid) is that idea
applied directly: full-bleed photo, oversized type, no added accent colour.

The old design was explicitly not something the owner wanted to preserve.

## Tokens

Defined in `theme/nell.scss`.

| Token | Value | Use |
|---|---|---|
| `$basalt` | `#16232b` | Body text. A genuinely blue-black, not tinted grey. |
| `$paper` | `#fbfaf7` | Background. Warm but deliberately not cream. |
| `$lake` | `#1f6f7a` | Links, focus rings. |
| `$sulfur` | `#e0a526` | Accent. Year markers and active nav only. |
| `$moss` | `#7a8b5a` | Reserved secondary. Currently unused. |
| `$rule` | `#ddd8ce` | Hairlines between entries. |
| `$muted` | `#5d6b73` | Legend and secondary text. |

The palette is grounded in the Mývatn field sites — basalt, lake water, and the
sulfur of the geothermal fields — rather than a generic academic scheme. This
matters: it's the reason to reject a warm-cream-plus-terracotta or
black-plus-acid-green palette if one gets proposed later. Those are defaults,
not choices.

## Type

- **Inter** (400/600/700 + italic) — everything: headings, navbar, body.
  Matches nbdev.fast.ai's stack exactly (`Inter, SF Pro Display,
  -apple-system, sans-serif`), one of the two reference sites. No separate
  display face for headings, unlike the original Space Grotesk / IBM Plex
  Sans pairing.
- **IBM Plex Mono** (400) — package names like `jackalope`, `phyr`. Kept as
  is; neither reference site was consulted for a monospace choice.

Root size 18px, line-height 1.65, measure capped at 68ch. Left-aligned
throughout.

Loaded from Google Fonts via `@import` in the rules layer. If self-hosting
later, the `woff2` caching headers are already in `netlify.toml`.

## Principles

**Spend boldness in one place — per page, not site-wide.** The publications
page has one strong move (sulfur year numerals in the left margin); the
homepage has one (the full-bleed hero). Neither page has a second. Don't add
a flourish to a page that already has one — remove one before adding one.

**Year markers are structure, not decoration.** They earn their size because a
publication list genuinely is a chronology. This is not licence for `01 / 02 /
03` style numbering on content that isn't a sequence.

**Accessibility floor**, already in the SCSS: visible `:focus-visible` rings in
`$lake`, `prefers-reduced-motion` respected. Keep both.

## Known risk (resolved)

The year-marker rule used absolute positioning inside
`#quarto-document-content h3` at `min-width: 1200px` — but that id is shared
by every page's content wrapper, not just publications, so once other pages
with real `###` subheadings existed (the `functionalr`/`github-rstudio`
tutorials), it hijacked those headings into giant floating sulfur text.
Confirmed via a real browser screenshot. Fixed by wrapping the publications
body in a `.publications-list` div (in `publications.qmd`) and rescoping
both the base rule and the media query to `.publications-list h3` instead
of the page-wide id, in `theme/nell.scss`.
