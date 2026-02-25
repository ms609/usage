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

  ok <- tryCatch({
    download.file(fileurl, gzfile)
    TRUE
  }, error = function(e) {
    message("Failed to download log for ", day, ": ", e$message)
    FALSE
  })

  if (!ok && file.exists(gzfile) && file.size(gzfile) == 0) {
    file.remove(gzfile)
  }
  ok
}
