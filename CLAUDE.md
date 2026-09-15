# CLAUDE.md

Context for Claude Code. Read this first.

## What this repo is

A Quarto rebuild of **lucasnell.com**, the personal academic site of Lucas A.
Nell (ecology and evolutionary biology: eco-evolutionary dynamics, genome
evolution, computational tools). **This is the live site as of 2026-09-14.**

It replaced `~/GitHub/nell_website`, a Hugo + blogdown site on a hand-forked
2017 theme (`kube`) — kept read-only, not deleted, as a fallback (still
deployed at `https://nell-website.netlify.app`, Netlify site name
`nell-website`, formerly `lucasnell`). See `docs/hugo-site-audit.md` for
what was wrong with it and what had to carry over; that work is done.

### Deployment

- GitHub: `lucasnell/nell_website_quarto` (public), `main` branch.
- Netlify site: `nell-website-quarto` (id `6c103c8d-d345-48c3-81da-9ef1ae127aa0`),
  dashboard at `https://app.netlify.com/projects/nell-website-quarto`.
  Custom domain `www.lucasnell.com` was transferred to this site from the old
  one via the dashboard's domain-management page; `lucasnell.com` 301s to
  `www.` automatically (Netlify's standard apex→www handling, no separate
  domain alias needed). DNS itself lives outside Netlify (Google Cloud DNS /
  originally Google Domains, `ns-cloud-a*.googledomains.com`) and was not
  touched — the switch happened entirely on the Netlify side, since Netlify
  routes by which site currently claims a hostname, independent of the DNS
  record text.
- **Continuous deployment is live**: pushing to `main` auto-builds and
  auto-publishes to production. It's wired up unconventionally, not through
  Netlify's dashboard "Link repository" flow (which does a GitHub App OAuth
  handshake) — instead: a Netlify **Build Hook** (`createSiteBuildHook`,
  `POST` to `https://api.netlify.com/build_hooks/6aa8520d81489793161c4859`
  triggers a build) plus a plain GitHub repo webhook on `push` events
  pointed at that URL. This was necessary because linking the repo via the
  `updateSite` API's `repo` field (which the initial cutover used to get
  manual builds/API-triggered builds working) sets Netlify's internal
  metadata but does **not** register a GitHub webhook — confirmed by
  checking `gh api repos/lucasnell/nell_website_quarto/hooks`, which came
  back `[]` after the API-based link. The dashboard flow would have
  registered one automatically; the build-hook route doesn't need that
  OAuth consent step at all, which is why it was used instead. If this ever
  needs debugging: GitHub webhook deliveries are visible at
  `gh api repos/lucasnell/nell_website_quarto/hooks/679282296/deliveries`.
- **Three real build bugs were only caught by actually triggering a build**
  — none were visible from reading `netlify.toml`, and this pin had never
  been build-tested against real Netlify infrastructure before continuous
  deployment was wired up (every prior render in this project was local).
  In order:
  1. `QUARTO_VERSION` as a bare `[build.environment]` variable does
     **nothing** — Netlify has no built-in support for it the way it does
     `NODE_VERSION`/`RUBY_VERSION`. A plain `command = "quarto render"`
     failed with `quarto: command not found` (exit 127).
  2. Fixed by adding the official `@quarto/netlify-plugin-quarto` build
     plugin (`[[plugins]] package = "..."` in `netlify.toml`) — but a
     plugin declared only in `netlify.toml` still isn't enough; Netlify
     also requires it as an actual npm dependency. Fixed by adding a
     minimal `package.json` (this repo has no other Node code; it exists
     solely so `npm install` can fetch the plugin).
  3. Even with the plugin installed and loading, it still failed in
     `onPreBuild` with `HttpError: Not Found`. Root cause (found by
     downloading the plugin's own tarball and reading `src/github.js`,
     since the error gave no detail): the plugin passes `QUARTO_VERSION`
     straight through as a literal GitHub release tag
     (`octokit.repos.getReleaseByTag`) with no transformation — and
     quarto-cli's real tags are `v`-prefixed (`v1.10.18`), not bare
     (`1.10.18`). `netlify.toml` now correctly reads
     `QUARTO_VERSION = "v1.10.18"`.
  4. **Do not remove the `[build] command`** without also removing the
     plugin, or vice versa — with the plugin installed, `[build] command`
     must stay unset (the plugin's `onBuild` hook runs `quarto render`
     itself); setting both risks the command running before the plugin has
     put `quarto` on `PATH`.

## Why Quarto

The old setup had three problems: a bespoke theme owned forever, R in the build
loop for content with no R in it, and a hand-maintained publications list. Quarto
removes all three. The owner is an R user, is not attached to the old design,
and keeps publications in Zotero. The site is small (~6 pages), so migration is
cheaper than upgrading Hugo across the Blackfriday/Goldmark and `.Data.Pages`
breaks.

## First-time setup

Two inputs are not in the repo and must be copied in by hand before anything
builds — `R/publications.R`'s `read_bib()` hard-stops if the bib file is
missing:

```bash
cp ~/Downloads/my-pubs.bib bib/my-pubs.bib   # Zotero export
```

Plus three icons in `img/` (currently empty), named exactly `open.svg`,
`closed.svg`, `pdf.svg` — copy from `../nell_website/static/img/`, but
re-export `pdf.svg` first (it's 808 KB for a 20px icon in the old repo).

## Commands

```bash
quarto preview          # local dev server
quarto render           # full build into _site/
```

R dependencies: `jsonlite`, `yaml`. Nothing else. Quarto's bundled pandoc does
the bib parsing.

## Architecture

### Site pages

`index.qmd`, `research.qmd`, `resources.qmd`, `cv.qmd`, and `publications.qmd`
are the five pages, all flat files at the project root. The navbar only
lists the latter four (Research/Publications/Resources/CV) — `index.qmd` has
no separate "About" entry since the navbar brand text already links home by
default in Quarto, and a second link to the same page was redundant.
Research entries are one consolidated page (five `##` sections in `weight`
order from the old Rmd front matter), not separate URLs — confirmed against
the live site, which renders research the same way.

`index.qmd` opens with a full-bleed hero: a photo of Lake Mývatn, Iceland
(`img/mvatn-sunset.jpg`, from the old site's unused `header_image.jpeg`,
Nell's own field site and the literal source of the `$basalt`/`$lake`/
`$sulfur` palette names) with the name and tagline overlaid, styled after
the ALA Labs / nbdev references in `docs/design-notes.md`. It's a `.hero
.column-screen` div; see the gotcha below for why `.column-screen` is used
instead of a hand-rolled full-bleed CSS trick, and why the rest of the
page's content is wrapped in a `.prose` div rather than relying on `main`'s
own width.

`img/favicon.png` is not a static image — it's regenerated from the old
site's own `favicon_plot.Rmd` (a tiny abstract plot of a simulated
two-species competitive-dynamics time series, no axes/labels), recolored to
`$sulfur`/`$lake` on a transparent background instead of the original's
firebrick/dodgerblue4-on-white. Wired up via `website.favicon` in
`_quarto.yml`. If it ever needs regenerating (e.g. a different size or
color), the generator is a plain R script (ggplot2 + `set.seed(2132209349)`
for the same trajectory), not committed anywhere in this repo since it's a
one-off — recreate from the old site's `favicon_plot.Rmd` if needed.

Resources has three real sub-pages, each `resources/<slug>/index.qmd` (an
`index.qmd` inside its own directory, not a flat file) so Netlify serves them
at a trailing slash matching the live URLs exactly, with no redirect needed:
`resources/functionalr/`, `resources/github-rstudio/`,
`resources/everglades-mutualism/`. Of the three, only `functionalr` has live
executed R chunks — it was rewritten to use only base R (`read.csv`/`rbind`)
instead of the original's `readr`/`dplyr` calls, to avoid adding dependencies
beyond `jsonlite`/`yaml`. Both `functionalr` and `github-rstudio` have
`toc: true` (a per-page override; the site default is `toc: false`) since
they're long, scannable tutorials — `resources/everglades-mutualism` doesn't,
since it's a short linear narrative.

### Interactive code cells (webr)

`functionalr` uses the `coatless/quarto-webr` extension (vendored in
`_extensions/coatless/webr/` — **must be committed**, since Netlify has no
step that would fetch it) to make several R examples live-editable in the
browser via WebAssembly, no server or R install needed for the reader. Only
self-contained sections were converted (R basics: functions, lists, apply,
for-loop; and the "fitting lots of models" capstone, whose four chunks are
all already visible and share state in page order) — the intentional-error
demos, `eval=FALSE` illustrative snippets, and the file-cleaning example
stayed as ordinary static `{r}` chunks, since converting those either
depends on a *hidden* knitr setup chunk (which a separate, entirely
browser-side webR session has no access to) or would newly execute code
that was previously only shown for illustration.

Two things to know before touching these cells:

- Each `{webr-r}` chunk needs `#| label: <name>` and, if it should show its
  output immediately rather than wait for the reader to press "Run Code",
  `#| autorun: true` (the extension's own default is `context: interactive`
  → `autorun: false`, i.e. nothing runs until clicked — not what this page
  wants, since the original always showed output immediately).
- See the freeze-cache gotcha below before assuming an edit "did nothing."

`_quarto.yml` sets `project.render: ["**/*.qmd"]`, so only `.qmd` files
render — no stray `.md` gets published as a site page. This is load-bearing:
`CLAUDE.md` and `docs/` live in this repo (moved back in from Box on
2026-09-15), and without this restriction Quarto's default project renders
every `.qmd`/`.md` under the project root, which would publish
`docs/design-notes.md`, `docs/hugo-site-audit.md`, `CLAUDE.md`,
`README.md`, and `HANDOFF.md` as live site pages.

### Publications pipeline

This is the core of the repo. Three pieces:

| File | Role |
|---|---|
| `bib/my-pubs.bib` | Zotero export. Source of truth for bibliographic facts. |
| `bib/publication-extras.yml` | Website-only data Zotero doesn't carry, keyed by citation key. |
| `R/publications.R` | Merges the two, emits markdown grouped by year. |

`publications.qmd` is a thin wrapper: source the script, call
`render_publications()` in an `output: asis` chunk.

Extras schema (all keys optional):

```yaml
CitationKey:
  access: open | closed          # which icon links the DOI
  pdf: <url>                     # adds a PDF icon
  mentees: ["Name X", "Name Y"]  # appends * to those authors
  title: <string>                # overrides bib title (casing, markup)
  override: {year, volume, issue, page, doi, journal}  # corrects a bad bib field
```

The bib is parsed via `quarto pandoc --from=bibtex --to=csljson`, not an R
package. Pandoc handles LaTeX escapes correctly (`{\'A}` -> Á), which naive
parsers do not.

### Build and deploy

`execute: freeze: auto` caches chunk output into `_freeze/`, which **is
committed**. Netlify then builds with the Quarto CLI alone: no R, no package
library, nothing to drift. Re-render locally when content changes, push the
result.

`netlify.toml` pins `QUARTO_VERSION = "1.10.18"`. The old site had no
equivalent, which is why production was building on Hugo 0.37.1 while local
used a version seven years newer. Do not remove the pin.

## Gotchas discovered the hard way

- **`%||%` must not coerce its left side.** It is often handed a whole extras
  block (a list). An earlier `as.character()` version was a hard build failure.
- **Pandoc normalises `1240--1244` to `1240-1244`** in CSL JSON. En dashes are
  reapplied in `format_locator()` by matching a hyphen between digits. Don't
  "simplify" that back to matching `--`.
- **Icon filenames are load-bearing**: `img/open.svg`, `img/closed.svg`,
  `img/pdf.svg`, exactly those stems.
- **Don't select on `#quarto-document-content` in `theme/nell.scss`** — that
  id is the page-content wrapper on *every* page, not just publications.
  The year-marker `h3` rule used to target it directly and ended up
  hijacking `###` headings on other pages. Scope page-specific rules to a
  wrapper class (e.g. `.publications-list`) added in that page's `.qmd`.
- **Run R under a UTF-8 locale.** Under `C`, accented author names mangle.
  macOS is fine by default; CI may not be.
- **`R/publications.R`'s `read_bib()` shells out to `quarto pandoc`**, so
  `quarto` must be on `PATH` when you run R directly (e.g. `Rscript`,
  RStudio's console) — not just reachable via `quarto render`. If it's
  installed somewhere non-standard (e.g. a tarball extract, not the signed
  macOS `.pkg`, which needs `sudo` and may not be an option on a locked-down
  machine), export `PATH` before rendering rather than reinstalling.
- **A `project.render` list replaces Quarto's default "render everything"
  entirely** — it doesn't layer on top of it. A negation-only list like
  `render: ["!docs/"]` renders nothing; excluding a path while keeping the
  rest requires an explicit positive pattern too, e.g.
  `["**/*.qmd", "!some-dir/"]`.
- **A hand-rolled `width:100vw; margin-left:calc(50% - 50vw)` full-bleed
  breakout does not reliably work against `<main>`** in Quarto's website
  layout — `main` is a grid *item* of `#quarto-content`'s `page-columns`
  grid, not a plain centered block, so percentage/vw math against it can
  look right at one viewport width and silently overflow at another
  (confirmed by measuring `getBoundingClientRect` in a real browser: it's
  not just a screenshot-timing artifact). Use Quarto's own `.column-screen`
  class instead (a fenced div, `::: {.column-screen}`) — its client-side
  layout JS (`quarto.js`'s `ensureInGrid`, which runs *after* the static
  HTML loads) detects it and promotes every ancestor up to `#quarto-content`
  to `.page-full`, which re-runs that ancestor's grid so it actually spans
  the viewport. Two things follow from this: (1) a static `curl`/view-source
  check of the HTML won't show the `.page-full` class — it's added at
  runtime, so verify in an actual browser, not the pre-JS markup; (2) any
  page-wide CSS rule that assumes `main`'s width (e.g. this repo's
  `main { max-width: 68ch; }`) must exempt `main.page-full`, or it'll clamp
  the very ancestor Quarto just widened — see `.prose` in `theme/nell.scss`,
  used to re-cap non-hero content on such a page instead.
- **`execute: freeze: auto` does not notice edits made purely inside a
  `{webr-r}` block.** Those blocks are pandoc raw content handled by the
  webr Lua filter, not knitr chunks — so knitr's own change-detection
  (which is what freeze actually keys off) never sees them change, and a
  stale `_freeze/<page>/execute-results/html.json` gets silently reused.
  Symptom: the page renders, but looks like the *previous* version of the
  edit (or, confusingly, like the webr filter never ran at all — literal
  `#| label:`/`#| autorun:` lines print as plain text instead of being
  parsed, because that stale cached HTML predates a later markup change).
  Fix: `rm -rf _freeze/resources/functionalr` (or whichever page) before
  re-rendering, any time you change something inside a `{webr-r}` chunk
  that isn't also a change to a real knitr `{r}` chunk on the same page.
- **`quarto preview`'s own file watcher can race a manual `quarto render`**
  run at the same time (both may rebuild the same page, and the preview's
  incremental rebuild doesn't necessarily clear freeze the way a full
  `rm -rf _site && quarto render` does) — if a change isn't showing up in
  the preview tab and a plain re-render doesn't explain why, kill the
  preview process, clear the relevant `_freeze/` entry, do one clean full
  render, and serve `_site/` statically (e.g. `python3 -m http.server`) to
  check, before assuming the change itself is wrong.

## Verification status

Full `quarto render` succeeds clean under Quarto 1.10.18 + R 4.6 — all eight
pages (`index`, `research`, `resources` + its three sub-pages, `cv`,
`publications`), correct authors/years/en dashes/icons on publications,
correct UTF-8 (Mývatn, Árni) on research, working internal links, and the
`functionalr` R chunks (including the intentionally-erroring demos) executing
without needing any package beyond base R. `_freeze/` was regenerated for
both R-executing pages.

All eight pages have now been screenshotted in a real (headless) browser at
1280px width and look right, including the publications page's sulfur year
markers in the left margin. That check caught a real bug: the year-marker
CSS targeted `#quarto-document-content h3`, which every page shares, so it
was also hijacking `###` headings on the `functionalr`/`github-rstudio`
tutorial pages into giant floating sulfur text. Fixed by scoping it to a
`.publications-list` wrapper div — see the gotcha below and
`docs/design-notes.md`'s "Known risk (resolved)".

The homepage hero (see Architecture/Gotchas) was verified with Playwright
driving real Chrome (`getBoundingClientRect` on `.hero`/`main`/`.prose`,
plus full-page screenshots) at both 400px and 1440px — full-bleed at both,
prose still capped at 68ch below it, no regression on `main`'s width on
pages without a hero. Dark-mode behavior hasn't been checked.

`functionalr`'s webr cells were verified with Playwright (real Chrome, not
just a quick headless screenshot — webR's WASM startup takes real time and
a premature screenshot shows nothing useful): editable Monaco editor,
correct syntax highlighting, `autorun` cells showing output without a click,
the intentional list-error demo still showing its error, the for-loop plot
rendering, and the four-chunk "fitting lots of models" capstone correctly
sharing state end to end (`model_fits[[1]]` prints the right `lm()` object).

## Open decisions

- **Oliver KM** appears as second-to-last author on the *Science* paper in the
  bib, but is absent from the current live site. Confirm which is right.
- **Within-year ordering** is alphabetical by citation key, so 2024 renders
  Botsch / GBE / *Science*. The live site puts *Science* first. If order matters,
  add a `rank:` field to the extras and sort on it.
- **Title case.** Better BibTeX exports Title Case, so all 13 entries carry a
  `title:` override. Switching the Zotero export to sentence case lets every
  one be deleted. Prefer fixing it upstream.

## Still to build

- [x] `index.qmd`, `research.qmd`, `resources.qmd`, `cv.qmd`
- [x] Homepage hero treatment — full-bleed Mývatn sunset photo with
      overlaid name/tagline, styled after the ALA Labs / nbdev references;
      see the Architecture and Gotchas notes above for how the full-bleed
      layout actually works
- [x] Port the five research writeups (as sections of `research.qmd`, since
      the live site renders them as one consolidated page, not separate URLs)
- [x] Port `functionalr`, `github-rstudio`, and `everglades-mutualism` as
      `resources/<slug>/index.qmd` (all three have real URLs on the live site)
- [x] Redirects so existing URLs keep resolving — `netlify.toml` rewrites the
      old trailing-slash top-level paths (`/research/`, `/publications/`,
      `/resources/`, `/cv/`); the three resources sub-pages need no redirect
      since they're each an `index.qmd` in their own directory
- [x] Verify the GitHub handle and other links in `_quarto.yml` — confirmed
      against the live site
- [x] Compress the two large plot-export SVGs on the research page —
      `svgo` only shaved ~3-4% off them (thousands of unmerged paths), so
      once `librsvg` was available they were rasterized instead:
      `rsvg-convert -w <1400-1600> -b white <svg> -o <png>` then
      `cwebp -q 90` (visually verified against the source SVG first —
      ImageMagick's built-in SVG delegate lacks Freetype and silently drops
      text labels, so it isn't safe for this). `nectar-model-diagram-simple`
      went 1.3 MB SVG → 231 KB WebP, `CIHMID-diagram-simple` 515 KB → 105 KB.
      Both are now `.webp` in `img/`; the SVGs were deleted (the old Hugo
      repo still has the originals if ever needed).
- [x] Make the coding tutorials more helpful/interactive — `functionalr` and
      `github-rstudio` both got `toc: true` (code-copy-on-hover was already
      a Quarto default, nothing to add there); `functionalr` additionally
      got live-editable webr cells for the self-contained R-basics sections
      and the modeling capstone (see Architecture). Deliberately did *not*
      port any content from `https://lucasnell.github.io/pranga/` (a full
      3-week course site) — porting the whole thing would duplicate and go
      stale against the live course, and no single lesson from it was an
      obviously better fit than a fresh post; revisit if a specific lesson
      becomes worth writing up standalone.
- [x] **Cutover, 2026-09-14.** `lucasnell.com`/`www.lucasnell.com` now point
      at this site (see Deployment above). Old open items that no longer
      apply post-cutover: the Oliver KM / within-year-ordering / title-case
      items under "Open decisions" below were about matching the *old* live
      site, which is no longer the source of truth — revisit them as
      ordinary content questions, not fidelity checks against a reference.

## Conventions

- Prose measure is 68ch. Don't widen it. The one deliberate exception is the
  homepage hero photo, which is full-bleed by design (see Architecture) —
  everything else on that page, and every other page, stays at 68ch.
- One accent colour (`$sulfur`) used in one place. See `docs/design-notes.md`
  before adding colour.
- Don't commit `_site/`. Do commit `_freeze/`.
