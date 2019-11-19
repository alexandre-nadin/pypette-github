smkSource("dge/deseq2.R")

suppressMessages(library("RColorBrewer"))
suppressMessages(library("pheatmap"))
suppressMessages(library("ggplot2"))

# ------------------
# Dge Results Table
# ------------------
dir.create(smkout$contrasts, showWarnings=TRUE, recursive=TRUE)
lapply(
  names(dgeResults),
  function(x) write.table(
    data.table(
      data.frame(dgeResults[[x]]),
      keep.rownames=geneidColname),
    file.path(smkout$contrasts, paste(x, ".tsv", sep="")), 
    append=F,
    row.names=F,
    col.names=T,
    quote=F,
    sep="\t"))

# ------------
# Dist Estims
# ------------
grDevices::png(smkout$distEstims)
plotDispEsts(dga)
dev.off()

# --------
# MA plot 
# --------
grDevices::pdf(smkout$maPlot)
lapply(dgeResults, DESeq2::plotMA)
dev.off()

# -------------
# Volcano Plot 
# -------------
grDevices::pdf(smkout$volcanoPlot)
for (i in 1:length(dgeResults)){
  plot(
    x    = dgeResults[[i]]$log2FoldChange,
    y    = -log10(dgeResults[[i]]$padj),
    main = "Volcano Plot", 
    xlab = "log2FC",
    ylab = "-log10(p.value.adj)",
    pch  = ".",
    cex  = 4,
    col  = ifelse(
            dgeResults[[i]]$padj <= smkp$dge$alpha,
            "red",
            "black"))
  abline(
    h= -log10(smkp$dge$alpha),
    v= 0,
    lty= 2,
    col="red")
  title(sub=paste(names(dgeResults)[i]))
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
