# nell_website_quarto

Quarto rebuild of lucasnell.com -- **this is the live site** as of
2026-09-14. Replaces the old Hugo site (`nell_website`), which is kept
read-only as a fallback at https://nell-website.netlify.app.

## Setup

Two things are missing and have to be copied in by hand:

```bash
cd ~/GitHub/nell_website_quarto
cp ~/Downloads/my-pubs.bib bib/my-pubs.bib
```

Three icons go in `img/`, named exactly `open.svg`, `closed.svg`, `pdf.svg`.
Copy them from `../nell_website/static/img/` -- but re-export `pdf.svg`
first, it's currently 808 KB for a 20-pixel icon.

R packages: `install.packages(c("jsonlite", "yaml"))`. Nothing else.

```bash
quarto preview
```

All navbar pages exist now (`index.qmd`, `research.qmd`, `resources.qmd`,
`cv.qmd`, `publications.qmd`), plus three sub-pages under `resources/`.

## How the publications page works

Zotero -> `bib/my-pubs.bib` is the source of truth for bibliographic facts.
`bib/publication-extras.yml` holds what Zotero doesn't carry: PDF links,
open vs. institutional access, mentored-student asterisks, title casing.

Adding a paper:

1. Export the Zotero collection over `bib/my-pubs.bib`.
2. Add an entry to `publication-extras.yml` only if it needs a PDF link,
   an access icon, or has a student co-author.
3. `quarto preview` to check, then commit and push.

The `.bib` is parsed by the pandoc bundled with Quarto, not by an R package,
so LaTeX escapes are handled correctly. This also fixes three compound
surnames the old site rendered wrong: Fernandez Marinone G, Ortiz Chavez D,
and Herrera Paredes S (previously "Marinone GF", "Chavez DO", "Paredes SH").

### Two things to fix upstream in Zotero

Doing either removes work from this repo permanently.

- **Title case.** Better BibTeX is exporting Title Case, so every entry
  currently needs a `title:` override. Switch the export to sentence case
  and you can delete all thirteen overrides.
- **The Greenbarg entry** has no volume, pages or DOI, and is filed under
  its 2017 online-first date rather than the 2018 issue. It's patched via
  `override:` for now; fixing Zotero lets that block go too.

## Build and deploy

`execute: freeze: auto` caches chunk output into `_freeze/`, which **is
committed**. Netlify then builds with the Quarto CLI alone -- no R, no
package library, nothing to drift. Re-render locally whenever content
changes and push the result.

`netlify.toml` pins `QUARTO_VERSION`. The old site had no equivalent, which
is why production was building on Hugo 0.37.1 while local used a version
seven years newer.

## Still to do

Full project context (architecture, gotchas, decisions, audit of the old
site, visual direction) lives in `CLAUDE.md` and `docs/`, kept outside this
repo in `~/Library/CloudStorage/Box-Box/claude/website`.

- [ ] Hero treatment for the homepage — currently just a plain portrait + bio
