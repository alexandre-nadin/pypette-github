suppressMessages(library("edgeR"))
suppressMessages(library(data.table)) 
# calculate rpkm from counts

# -----------------------
# Import data from Feature Counts
# ------------------------
fCounts <- read.delim(file=smkin$counts, header=TRUE)
fCountsData <- fCounts[
  , 
  -which(
    tolower(names(fCounts))
    %in% 
    tolower(smkp$fCountsDataCols) )]

fCountsAnnotation <- fCounts[
  , 
  which(
    tolower(names(fCounts))
    %in% 
      tolower(smkp$fCountsDataCols))]
         
geneidColname <- 'Geneid'
geneidIdx <- which(tolower(smkp$fCountsDataCols) %in% tolower(geneidColname))
rownames(fCountsData) <- fCounts[[geneidIdx]]

# -------------------------
# Import metadata
# ------------------------
metadata = read.delim(smkin$metadata, header=TRUE)
# Reordering counts matrix to have samples ordered as in metadata
fCountsData <- fCountsData[,match(metadata[,1], colnames(fCountsData))] # assuming that the first column in metadata is sample name

# -------------------------
# Calculate RPKM
# -------------------------
y = DGEList(counts=fCountsData, genes = fCountsAnnotation)
# filter on expression
keep <- rowSums(cpm(y)> 1) >= smkp$dge$minSamples
fCountsRPKM = rpkm(y, log=T, gene.length =y$genes$Length)
# evaluate pca only for the N most variable genes 
N = 500
vary <- apply(fCountsRPKM[keep,],1,var)
NMostVariable <- names(sort(vary, decreasing = T)[1:N])
fCountsRPKM_MV <- fCountsRPKM[NMostVariable,]

