# Handoff note

_Last updated: 2026-09-15_

## What this is

A Quarto rebuild of [lucasnell.com](https://www.lucasnell.com), replacing
the old Hugo + blogdown site (`nell_website`). **This is the live site.**
Cut over from the old one on 2026-09-14.

## Where things live

| What | Where |
|---|---|
| Live site | https://www.lucasnell.com (`lucasnell.com` redirects to `www`) |
| This repo | https://github.com/lucasnell/nell_website_quarto (public, `main` branch) |
| Hosting | Netlify site `nell-website-quarto` |
| Old site (kept as read-only fallback) | https://nell-website.netlify.app |

## How to update the site

Edit, commit, push to `main` — Netlify auto-builds and auto-deploys.
See the README's **Updating the site** section for one exception (pages
with live R code need a local `quarto render` first) and general tips.

Continuous deployment is wired via a Netlify Build Hook + a plain GitHub
webhook, not Netlify's usual "Link repository" dashboard flow — see
`CLAUDE.md` (location below) if this ever needs debugging.

## Architecture, at a glance

- **Publications** (`publications.qmd`) are generated from a Zotero export
  (`bib/my-pubs.bib`) plus a hand-maintained sidecar
  (`bib/publication-extras.yml`) for things Zotero doesn't carry (PDF
  links, access icons, mentored-student asterisks). Merged by
  `R/publications.R`.
- **Research** (`research.qmd`) is one page, five sections — matches how
  the content reads on the live site, not separate URLs per project.
- **Resources** (`resources.qmd`) links to three real sub-pages under
  `resources/<slug>/`. One of them, `functionalr`, has live-editable R
  code cells that run in the browser via WebAssembly (no server, no
  install) — see the `webr` extension in `_extensions/`.
- **Homepage** has a full-bleed photo hero (Lake Mývatn, Iceland — also
  where the site's color palette gets its name).
- Design is a deliberate mix of two references (ALA Labs, nbdev.fast.ai):
  confident type (Inter), generous whitespace, one accent color used in
  exactly one place per page.

## Full context (not in this repo)

Detailed architecture notes, every build/deploy gotcha hit along the way,
design rationale, and open content decisions all live in `CLAUDE.md` and
`docs/` — kept deliberately **outside** this repo, at
`~/Library/CloudStorage/Box-Box/claude/website` on the machine this was
built on. That's the file to read for anything not covered here.

## Known open items

- No hero/hierarchy pass beyond what's here — homepage, research, and
  publications each have one intentional visual "flourish" and nothing
  else; that's a deliberate choice, not an oversight, but worth
  reconsidering if the site grows.
- A few small content questions inherited from the old site were never
  resolved (an author's presence on one paper, within-year publication
  ordering, Zotero export casing) — see `CLAUDE.md`'s "Open decisions"
  for specifics.
- Dark-mode rendering and very narrow viewports have not been checked.
