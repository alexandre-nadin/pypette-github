# ---------------------
# Snakemake parameters
# ---------------------
smkp   <- snakemake@params
smkin  <- snakemake@input
smkout <- snakemake@output

smkScript  <- Sys.getenv("_PYPETTE_SCRIPT")
smkModules <- Sys.getenv("_PYPETTE_MODULES")

smkSource  <- function(script) {
  print(paste("[smkSource] ", smkScript))
  source(file.path(smkModules, script))
}

source(smkScript)
