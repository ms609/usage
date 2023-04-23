LogFile <- function(day) {
  paste0("logs/", day, ".csv.gz")
}

GetLogs <- function(day) {
  options(timeout = max(300, getOption("timeout")))
  
  packages <- c(
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
    download.file(fileurl, gzfile)
  }
  
  logs <- read.csv(gzfile)
  pkgLogs <- logs[logs$package %in% packages,
                  c("r_version", "r_os", "package", "version", "country")]
  if (!dir.exists("logs")) {
    dir.create("logs")
  }
  gzcon <- gzfile(LogFile(day))
  on.exit(close(gzcon))
  write.csv(pkgLogs, gzcon)
}

day <- Sys.Date() - 3
while (as.POSIXlt(day)$year + 1900 > 2012) {
  if (!file.exists(LogFile(day))) {
    GetLogs(day)
    break
  }
  day <- day - 1
}
