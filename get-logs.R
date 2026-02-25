source("utils.R")

GetLogs <- function(day) {
  if (!DownloadRawLog(day)) return(FALSE)

  gzfile  <- paste0(day, ".csv.gz")
  logs    <- read.csv(gzfile)
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
