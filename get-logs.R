if (!dir.exists("logs")) {
  dir.create("logs")
}

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
                  c("date", "r_version", "r_os",
                    "package", "version", "country")]

  gzcon <- gzfile(LogFile(day), "w")
  write.csv(pkgLogs, gzcon)
  tryCatch(close(gzcon),
           error = function(e) message("Couldn't close connection"))
}

day <- Sys.Date() - 3
while (as.POSIXlt(day)$year + 1900 > 2012) {
  if (!file.exists(LogFile(day))) {
    GetLogs(day)
    #break
  }
  day <- day - 1
}
