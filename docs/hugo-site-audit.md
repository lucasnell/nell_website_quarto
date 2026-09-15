# Audit of the old Hugo site

Findings from `~/GitHub/nell_website` (Hugo + blogdown, `kube` theme fork),
recorded so the rebuild doesn't reintroduce them and so nothing is lost at
cutover. The old site is still live — treat it as read-only.

## Bugs not to reproduce

**Research and Resources were `noindex`.** `layouts/_default/baseof.html` set
`$default_noindex_kinds := slice "section" "taxonomy" "taxonomyTerm"`. Research
and Resources are Hugo sections, so both carried
`<meta name="robots" content="noindex">` and were excluded from search engines.
Confirmed live. Quarto indexes everything by default; just don't add a blanket
exclusion.

**`baseURL = "www.lucasnell.com"`** had no scheme, breaking canonical URLs, RSS
and sitemap entries. `_quarto.yml` now uses `site-url: https://www.lucasnell.com`.

**A `[[headers]]` block sat in `config.toml`** — Netlify syntax pasted into Hugo
config, silently inert. Those headers now live in `netlify.toml`, where they work.

**Two stylesheets 404'd on every page.** `layouts/partials/header.html` requested
`/font-awesome/css/font-awesome.min.css` and `/css/academicons.css`; neither
existed in `static/` or the theme. The `fa-`/`ai-` icons were therefore dead.

**Mismatched tag** in `layouts/section/research.html`:
`<h1 id="{{ .Title }}">{{ .Title }}</h3>`. Titles were also used raw as `id`
attributes, producing ids containing spaces and question marks.

**Compound surnames were mangled** in the hand-written publications list:
"Marinone GF", "Chavez DO" and "Paredes SH" should be Fernández Marinone G,
Ortiz Chavez D and Herrera Paredes S. The bib has them right and the new
pipeline fixes them automatically.

## Page weight to fix during the port

`static/img` was 15 MB. Compress before copying anything across.

| File | Size | Loaded on |
|---|---|---|
| `nectar-model-diagram-simple.svg` | 1.79 MB | research |
| `portrait.jpg` | 1.86 MB | homepage |
| `header_image.jpeg` | 960 KB | every page |
| `pdf.svg` | 808 KB | publications, at 20px |
| `CIHMID-diagram-simple.svg` | 758 KB | research |

The two big SVGs are plot exports with thousands of unmerged paths; SVGO
typically cuts 90%+. `pdf.svg` at 808 KB for a 20-pixel icon is the worst
offender and must be re-exported before use.

About 7 MB of images (`throughfall.JPG`, `first_gator.jpg`, `Jupiter_nest.jpg`,
`tracks_under_trap.jpg`) are orphans from a deleted Photos page. Don't port them.

## Content inventory

```
content/_index.md            homepage
content/publications.md      -> publications.qmd (DONE)
content/cv.md                CV, embedded as an iframe
content/research/            5 entries, all .Rmd with NO evaluated R code:
                               aphids_eco-evo, coexistence-theory,
                               midges_genome-evolution, nectar_microbes,
                               pseudomonas-aphids
content/resources/           functionalr (needs R), github_rstudio,
                               mutalism_everglades
```

The research entries can become plain `.md`. Only `functionalr` needs `.qmd`
with live chunks.

Two large standalone pages are served straight out of `static/`:
`github_gsis.html` (1.2 MB) and `R1_tidy_data.html` (894 KB). They are linked
resources, not Hugo-rendered. Decide whether to port, keep as static assets, or
drop.

Ordering in the old site used `weight = 998` / `999` on research entries —
brittle. Pick something explicit.

## Before cutover

- **Enumerate live URLs** and write redirects. Known top-level paths: `/`,
  `/research/`, `/publications/`, `/resources/`, `/cv/`. Research and resources
  sub-page URLs need checking against the live site rather than assumed —
  `layouts/section/research.html` rendered entries onto a single page via
  `.Data.Pages`, so per-entry URLs may or may not exist.
- **`static/CNAME`** contains two domains, which GitHub Pages doesn't even
  support, and `static/.nojekyll` is another GitHub Pages leftover. Both are
  dead weight now that hosting is Netlify. Don't port either.
- **`static/_redirects`** exists but contains only a comment.
- Google Analytics was hardcoded into `baseof.html` *and* set via
  `googleAnalytics` in `config.toml`. Decide whether to carry analytics over at
  all; if so, configure it once.
- `.DS_Store` was never gitignored and copies are scattered through the old
  repo. The new `.gitignore` covers it.

## Dead code in the old repo

`layouts/section/` still contains `people.html`, `photos.html` and `posts.html`
with no corresponding content, and `layouts/partials/people/` likewise. The old
`README.md` table of contents links to People, Photos and Prospective Students
sections that were deleted from its own body. None of this needs porting.
