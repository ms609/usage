if (!dir.exists("logs")) {
  dir.create("logs")
}

packages <- c(
  "ips",
  "PlotTools",
  "Quartet",
  "Rogue",
  "Ternary",
  "TreeDist",
  "TreeSearch",
  "TreeTools",
  "TBRDist"
)

LogFile <- function(day) {
  paste0("logs/", day, ".csv.gz")
}

# Download the raw CRAN log for `day` to the working directory if not already
# cached.  Returns TRUE on success, FALSE on failure (partial files are
# cleaned up).
DownloadRawLog <- function(day) {
  gzfile <- paste0(day, ".csv.gz")
  if (file.exists(gzfile)) return(TRUE)

  options(timeout = max(300, getOption("timeout")))
  year    <- as.POSIXlt(day)$year + 1900
  fileurl <- paste0("http://cran-logs.rstudio.com/", year, "/", gzfile)

  # download.file() returns non-zero on failure and may only warn rather than
  # error (e.g. HTTP 404), so capture the return value rather than relying on
  # tryCatch alone.
  status <- tryCatch(
    suppressWarnings(download.file(fileurl, gzfile, quiet = TRUE)),
    error = function(e) {
      message("Failed to download log for ", day, ": ", e$message)
      1L
    }
  )

  ok <- status == 0 && file.exists(gzfile) && file.size(gzfile) > 0
  if (!ok) {
    if (file.exists(gzfile)) file.remove(gzfile)
    message("Failed to download log for ", day, " (HTTP error or empty file)")
  }
  ok
}
