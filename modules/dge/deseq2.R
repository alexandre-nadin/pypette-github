library("DESeq2")
library("RColorBrewer")
library("pheatmap")
library("ggplot2")
#library("edgeR")

# ---------------------
# Snakemake parameters
# ---------------------
smkp   <- snakemake@params
smkin  <- snakemake@input
smkout <- snakemake@output

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

dds <- DESeqDataSetFromMatrix(
  countData= fCountsData, 
  colData  = read.delim(smkin$metadata, header=TRUE), 
  design   = as.formula(smkp$dge$design$string))

row.names(dds) <- rowData(dds)$fCountsData

filter <- rowSums(counts(dds) >= smkp$dge$minCounts) >= smkp$dge$minSamples
ddsFiltered <- dds[filter,]

ddsFiltered$condition <- relevel(
  ddsFiltered[[smkp$dge$design$refFactor]], 
  ref = smkp$dge$design$refLevel)

dga <- DESeq(object = ddsFiltered, 
             test = "Wald", 
             fitType = "parametric", 
             betaPrior = FALSE,
             minReplicatesForReplace = Inf)

# TODO: PLOT
grDevices::png(smkout$distEstims)
plotDispEsts(dga)
dev.off()

contrasts = resultsNames(dga)[- which(resultsNames(dga) %in% 'Intercept')]

dresults <- list()

for (contrast in contrasts) {
  dresults[[contrast]] <- results(
    dga, 
    name = contrast,
    cooksCutoff = Inf,
    independentFiltering = TRUE, 
    alpha = smkp$dge$alpha,
    pAdjustMethod = "BH")
}


# 
#lapply(dresults, summary)

# --------
# MA plot 
# --------
grDevices::pdf(smkout$maPlot)
lapply(dresults, DESeq2::plotMA)
dev.off()

# -------------
# Volcano Plot 
# -------------
grDevices::pdf(smkout$volcanoPlot)
for (i in 1:length(dresults)){
  plot(
    x    = dresults[[i]]$log2FoldChange,
    y    = -log10(dresults[[i]]$padj),
    main = "Volcano Plot", 
    xlab = "log2FC",
    ylab = "-log10(p.value.adj)",
    pch  = ".",
    cex  = 4,
    col  =ifelse(
          dresults[[i]]$padj <= smkp$dge$alpha,
          "red",
          "black"))
  abline(
    h= -log10(smkp$dge$alpha),
    v= 0,
    lty= 2,
    col="red")
  title(sub=paste(names(dresults)[i]))
}
dev.off()


pasteAttrs <- function(c1, c2, sep='-') {
  return(paste(c1, c2, sep=sep))
}

objectAttrs <- function(attr, obj) { return(obj[[attr]]); }

# ----------
# pheatmap 
# ----------
vsd <- vst(dga, blind=FALSE)
sampleDists <- dist(t(assay(vsd)))
sampleDistMatrix <- as.matrix(sampleDists)
rownames(sampleDistMatrix) <- 
  Reduce(
    pasteAttrs, 
    append( 
      list(rownames(sampleDistMatrix)),
      lapply(
        smkp$dge$design$factors, 
        objectAttrs, 
        obj=vsd)))
colnames(sampleDistMatrix) <- NULL
colors <- colorRampPalette( rev(brewer.pal(9, "Blues")) )(255)

grDevices::png(smkout$pheatMap)
pheatmap(
  cellwidth=NA, cellheight=NA,
  sampleDistMatrix,
  clustering_distance_rows=sampleDists,
  clustering_distance_cols=sampleDists,
  col=colors,
  main="Heatmap of Sample Distances"
)
dev.off()

# -----
# PCA
# -----
grDevices::pdf(smkout$pca)
for (factor in smkp$dge$design$factors) {
  pcaData <- plotPCA(
    vsd,
    intgroup= c(factor),
    returnData=TRUE)
  pcaPercVars <- round(100 * attr(pcaData, "percentVar"))
  print(ggplot(
    pcaData, 
    aes(PC1, PC2))                                       + 
     geom_point(aes_string(color=`factor`), size=3)      + 
     xlab(paste0("PC1: ", pcaPercVars[1], "% variance")) +
     ylab(paste0("PC2: ", pcaPercVars[2], "% variance")) +
     coord_fixed()                                       + 
     ggtitle(paste("PCA", factor))                       +
     theme(plot.title = element_text(hjust = 0.5)))
}
dev.off()

