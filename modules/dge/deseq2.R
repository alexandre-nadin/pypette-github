suppressMessages(library("DESeq2"))
suppressMessages(library("edgeR"))
suppressMessages(library(data.table))

# ---------------
# FeatureCounts
# ---------------
fCounts <- read.delim(file=smkin$counts, 
                      header=TRUE,
                      check.names = FALSE)

fCountsData <- fCounts[
  , 
  -which(
    tolower(names(fCounts)) 
    %in% 
    tolower(smkp$fCountsDataCols) )]

geneidColname <- 'Geneid'
geneidIdx <- which(tolower(smkp$fCountsDataCols) %in% tolower(geneidColname))
rownames(fCountsData) <- fCounts[[geneidIdx]]

# Reordering counts matrix to have samples ordered as in metadata
metadata = read.delim(smkin$metadata, header=TRUE) 
fCountsData <- fCountsData[,match(metadata[,1], colnames(fCountsData))] # assuming that the first column in metadata is sample name

dds <- DESeqDataSetFromMatrix(
  countData= fCountsData, 
  colData  = metadata, 
  design   = as.formula(smkp$dge$design$string))

filter <- rowSums(cpm(counts(dds)) >= smkp$dge$minCounts) >= smkp$dge$minSamples
ddsFiltered <- dds[filter,]

ddsFiltered[[smkp$dge$design$refFactor]] <- relevel(
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
  # sorting gene list according to significance
  dgeResults[[contrast]] <- dgeResults[[contrast]][order(dgeResults[[contrast]]$pvalue, decreasing = F),]
}
