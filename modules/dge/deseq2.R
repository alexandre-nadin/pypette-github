suppressMessages(library("DESeq2"))
suppressMessages(library("edgeR"))
suppressMessages(library(data.table))

# ---------------
# FeatureCounts
# ---------------
fCounts <- read.delim(file=smkin$counts, header=TRUE)
fCountsData <- fCounts[
  , 
  -which(
    tolower(names(fCounts)) 
    %in% 
    tolower(smkp$fCountsDataCols) )]

geneidColname <- 'Geneid'
geneidIdx <- which(tolower(smkp$fCountsDataCols) %in% tolower(geneidColname))
rownames(fCountsData) <- fCounts[[geneidIdx]]

dds <- DESeqDataSetFromMatrix(
  countData= fCountsData, 
  colData  = read.delim(smkin$metadata, header=TRUE), 
  design   = as.formula(smkp$dge$design$string))

filter <- rowSums(cpm(counts(dds)) >= smkp$dge$minCounts) >= smkp$dge$minSamples
ddsFiltered <- dds[filter,]

ddsFiltered$condition <- relevel(
  ddsFiltered[[smkp$dge$design$refFactor]], 
  ref = smkp$dge$design$refLevel)

dga <- DESeq(
         object = ddsFiltered, 
         test = "Wald", 
         fitType = "parametric", 
         betaPrior = FALSE,
         minReplicatesForReplace = Inf)

contrasts = resultsNames(dga)[- which(resultsNames(dga) %in% 'Intercept')]

dgeResults <- list()
for (contrast in contrasts) {
  dgeResults[[contrast]] <- results(
    dga, 
    name                 = contrast,
    cooksCutoff          = Inf,
    independentFiltering = TRUE, 
    alpha                = smkp$dge$alpha,
    pAdjustMethod        = "BH")
}
