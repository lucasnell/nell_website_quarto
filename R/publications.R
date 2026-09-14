# Builds the publications list from Zotero's .bib plus a sidecar of
# website-only extras (PDF links, access type, mentored-student authors).
#
# The .bib is parsed by the pandoc that ships with Quarto rather than by an
# R package. Pandoc already knows how to unescape LaTeX ({\'A} -> A-acute,
# {{Plasmodium}} -> Plasmodium), which naive parsers get wrong.

suppressPackageStartupMessages({
  library(jsonlite)
  library(yaml)
})

ME <- list(family = "Nell", initials = "LA")

# Falls back to `y` when `x` is absent or an empty string. Must not coerce:
# `x` is often a list (a whole extras block), which as.character() mangles.
`%||%` <- function(x, y) {
  if (is.null(x)) return(y)
  if (is.character(x) && length(x) == 1L && !nzchar(x)) return(y)
  x
}

read_bib <- function(bib_file = "bib/my-pubs.bib") {
  stopifnot(file.exists(bib_file))
  json <- system2(
    "quarto",
    c("pandoc", "--from=bibtex", "--to=csljson", shQuote(normalizePath(bib_file))),
    stdout = TRUE
  )
  entries <- jsonlite::fromJSON(paste(json, collapse = "\n"), simplifyVector = FALSE)
  stats::setNames(entries, vapply(entries, `[[`, character(1), "id"))
}

initials_of <- function(given) {
  if (is.null(given) || !nzchar(given)) return("")
  parts <- unlist(strsplit(given, "[ .-]+"))
  parts <- parts[nzchar(parts)]
  paste0(substr(parts, 1, 1), collapse = "")
}

format_authors <- function(authors, mentees = character()) {
  names_out <- vapply(authors, function(a) {
    fam <- a[["family"]] %||% ""
    ini <- initials_of(a[["given"]])
    nm <- trimws(paste(fam, ini))
    if (identical(fam, ME$family) && identical(ini, ME$initials)) {
      nm <- paste0("__", nm, "__")
    } else if (nm %in% mentees) {
      nm <- paste0(nm, "\\*") # mentored undergraduate author
    }
    nm
  }, character(1))
  paste(names_out, collapse = ", ")
}

issued_year <- function(e) {
  dp <- e[["issued"]][["date-parts"]]
  if (is.null(dp)) return(NA_integer_)
  as.integer(dp[[1]][[1]])
}

# vol(issue): pages -- any part may be absent
format_locator <- function(volume, issue, page) {
  out <- ""
  if (nzchar(volume)) out <- volume
  if (nzchar(issue)) out <- paste0(out, "(", issue, ")")
  # pandoc normalises "1240--1244" to "1240-1244" in CSL JSON, so match a
  # plain hyphen between digits rather than the LaTeX double hyphen.
  page <- sub("([0-9])\\s*-+\\s*([0-9])", "\\1\u2013\\2", page)
  if (nzchar(page)) out <- if (nzchar(out)) paste0(out, ": ", page) else page
  out
}

icon <- function(url, type) {
  alt <- c(open = "Open access", closed = "Institutional access", pdf = "PDF")[[type]]
  sprintf(
    '<a href="%s" class="pub-icon" aria-label="%s" title="%s"><img src="img/%s.svg" alt=""></a>',
    url, alt, alt, type
  )
}

format_entry <- function(e, x) {
  # x = the extras list for this citation key (possibly empty)
  ov <- x[["override"]]

  year    <- ov[["year"]] %||% issued_year(e)
  volume  <- as.character(ov[["volume"]] %||% e[["volume"]] %||% "")
  issue   <- as.character(ov[["issue"]] %||% e[["issue"]] %||% "")
  page    <- as.character(ov[["page"]] %||% e[["page"]] %||% "")
  doi     <- as.character(ov[["doi"]] %||% e[["DOI"]] %||% "")
  journal <- as.character(ov[["journal"]] %||% e[["container-title"]] %||% "")
  title   <- as.character(x[["title"]] %||% e[["title"]] %||% "")

  mentees <- unlist(x[["mentees"]] %||% character())
  authors <- format_authors(e[["author"]], mentees)
  locator <- format_locator(volume, issue, page)

  links <- character()
  access <- as.character(x[["access"]] %||% "")
  if (nzchar(access) && nzchar(doi)) {
    links <- c(links, icon(paste0("https://doi.org/", doi), access))
  } else if (nzchar(doi)) {
    links <- c(links, sprintf('<a href="https://doi.org/%s">doi:%s</a>', doi, doi))
  }
  if (!is.null(x[["pdf"]])) links <- c(links, icon(x[["pdf"]], "pdf"))

  paste0(
    "- ", authors, ". ", year, ". ", title, ". *", journal, "*",
    if (nzchar(locator)) paste0(" ", locator) else "", ".",
    if (length(links)) paste0(" ", paste(links, collapse = " ")) else ""
  )
}

# Emit the whole publications list as markdown, newest year first.
render_publications <- function(bib_file = "bib/my-pubs.bib",
                                extras_file = "bib/publication-extras.yml") {
  entries <- read_bib(bib_file)
  extras <- if (file.exists(extras_file)) yaml::read_yaml(extras_file) else list()

  keys <- names(entries)
  years <- vapply(keys, function(k) {
    ov <- extras[[k]][["override"]][["year"]]
    if (!is.null(ov)) as.integer(ov) else issued_year(entries[[k]])
  }, integer(1))

  unknown <- setdiff(names(extras), keys)
  if (length(unknown)) {
    warning("Extras with no matching bib entry: ", paste(unknown, collapse = ", "))
  }

  for (y in sort(unique(years), decreasing = TRUE)) {
    cat("\n### ", y, "\n\n", sep = "")
    for (k in keys[years == y]) {
      cat(format_entry(entries[[k]], extras[[k]] %||% list()), "\n")
    }
  }
  invisible(NULL)
}
