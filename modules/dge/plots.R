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

