# backfill-ips.R
#
# For each existing log file that lacks `ips` data, download the corresponding
# CRAN log, extract ips rows, merge them into the stored file, and save.
# Processes one day at a time (most recent first) so you can run incrementally.
#
# Run repeatedly until all historic log files contain ips data (or until
# the download fails because the CRAN log is not yet available / too old).

source("get-logs.R")   # brings LogFile() into scope

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

NeedsIps <- function(day) {
  lf <- LogFile(day)
  if (!file.exists(lf)) return(FALSE)   # no local log yet — skip
  existing <- read.csv(lf)
  !"ips" %in% existing[["package"]]
}

BackfillDay <- function(day) {
  lf     <- LogFile(day)
  year   <- as.POSIXlt(day)$year + 1900
  gzfile <- paste0(day, ".csv.gz")

  options(timeout = max(300, getOption("timeout")))

  # Download the raw CRAN log if not cached locally
  if (!file.exists(gzfile)) {
    fileurl <- paste0("http://cran-logs.rstudio.com/", year, "/", gzfile)
    ok <- tryCatch({
      download.file(fileurl, gzfile)
      TRUE
    }, error = function(e) {
      message("Failed to download log for ", day, ": ", e$message)
      FALSE
    })
    if (!ok) return(invisible(FALSE))
  }

  raw <- read.csv(gzfile)

  # Rows for all monitored packages (same columns as get-logs.R)
  fresh <- raw[raw[["package"]] %in% packages,
               c("date", "r_version", "r_os", "package", "version", "country")]

  # Merge with existing log, replacing any rows for the same packages to avoid
  # duplicates, then re-save
  existing <- read.csv(lf)
  # Drop rows for packages that are now being refreshed (in case of partial data)
  existing <- existing[!existing[["package"]] %in% packages, ]
  merged   <- rbind(existing[, c("date", "r_version", "r_os",
                                 "package", "version", "country")],
                    fresh)

  gzcon <- gzfile(lf, "w")
  write.csv(merged, gzcon)
  tryCatch(close(gzcon),
           error = function(e) message("Couldn't close connection"))

  message("Updated ", lf, " (+", nrow(fresh), " ips-era rows, ",
          sum(fresh$package == "ips"), " ips)")
  invisible(TRUE)
}

# Walk backwards from yesterday, process the first log that lacks ips data
day <- Sys.Date() - 1
while (as.POSIXlt(day)$year + 1900 > 2012) {
  if (NeedsIps(day)) {
    BackfillDay(day)
    break
  }
  day <- day - 1
}
