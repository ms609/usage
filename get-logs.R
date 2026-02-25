if (!dir.exists("logs")) {
  dir.create("logs")
}

LogFile <- function(day) {
  paste0("logs/", day, ".csv.gz")
}

GetLogs <- function(day) {
  options(timeout = max(300, getOption("timeout")))
  
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
  
  year <- as.POSIXlt(day)$year + 1900
  gzfile <- paste0(day, ".csv.gz")
  if (!file.exists(gzfile)) {
    fileurl <- paste0("http://cran-logs.rstudio.com/", year, "/", gzfile)
    ok <- tryCatch({
      download.file(fileurl, gzfile)
      TRUE
    }, error = function(e) {
      message("Failed to download log file: ", e$message)
      FALSE
    })
    # Remove any zero-byte or partial file left by a failed download
    if (!ok) {
      if (file.exists(gzfile) && file.size(gzfile) == 0) {
        file.remove(gzfile)
      }
      return(FALSE)
    }
  }
  
  if (!file.exists(gzfile)) {
    return(FALSE)
  }
  logs <- read.csv(gzfile)
  pkgLogs <- logs[logs[["package"]] %in% packages,
                  c("date", "r_version", "r_os",
                    "package", "version", "country")]

  gzcon <- gzfile(LogFile(day), "w")
  write.csv(pkgLogs, gzcon)
  tryCatch(close(gzcon),
           error = function(e) message("Couldn't close connection"))
  TRUE
}

day <- Sys.Date() - 3
while (as.POSIXlt(day)$year + 1900 > 2012) {
  if (!file.exists(LogFile(day))) {
    ok <- GetLogs(day)
    if (ok) {
      # Successfully fetched a log; stop for this run
      break
    }
    # Download failed (e.g. 404) — skip this date and try the next older day
    message("Skipping ", day, " (download failed); trying earlier dates")
  }
  day <- day - 1
}
