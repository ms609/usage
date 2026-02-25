# backfill-ips.R
#
# For each existing log file that lacks `ips` data, download the corresponding
# CRAN log, extract ips rows, merge them into the stored file, and save.
# Processes one day at a time (most recent first) so you can run incrementally.
#
# Run repeatedly until the script exits silently (all historic logs checked).

source("utils.R")

NeedsIps <- function(day) {
  lf <- LogFile(day)
  if (!file.exists(lf)) return(FALSE)   # no local log — nothing to backfill
  !"ips" %in% read.csv(lf)[["package"]]
}

BackfillDay <- function(day) {
  lf <- LogFile(day)
  if (!DownloadRawLog(day)) {
    # Return NA to signal a download failure so the caller skips this date
    # rather than stopping entirely.
    return(invisible(NA))
  }

  gzfile <- paste0(day, ".csv.gz")
  raw    <- read.csv(gzfile)

  # Rows for all monitored packages (same columns as get-logs.R)
  fresh <- raw[raw[["package"]] %in% packages,
               c("date", "r_version", "r_os", "package", "version", "country")]

  # Merge with existing log, replacing any rows for the same packages to avoid
  # duplicates, then re-save
  existing <- read.csv(lf)
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

# Walk backwards from the day before ips was first collected by get-logs.R.
# Each run backfills one date then stops; skip dates that already have ips
# data, lack a local log, or whose download fails.
day <- as.Date("2026-02-15")
while (as.integer(format(day, "%Y")) > 2012) {
  if (NeedsIps(day)) {
    result <- BackfillDay(day)
    if (isTRUE(result)) {
      # Successfully backfilled one date; stop for this run
      break
    }
    # Download failed — skip this date and continue to the next older day
    message("Skipping ", day, " (download failed); trying earlier dates")
  }
  day <- day - 1
}
