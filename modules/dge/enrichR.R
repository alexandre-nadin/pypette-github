smkSource("dge/deseq2.R")
dir.create(smkout$dir, showWarnings=FALSE)

suppressMessages(library("enrichR"))
suppressMessages(library("openxlsx"))

databases <- listEnrichrDbs()

# -------------------------
# enrichment Parameters
# -------------------------
# databases to make the enrichment of
enrich.databases <- c("GO_Biological_Process_2018",
                      "GO_Cellular_Component_2018",
                      "GO_Molecular_Function_2018",
                      "Reactome_2016",
                      "KEGG_2016",
                      "WikiPathways_2016",
                      "BioCarta_2016")

# -------------------------
# Perform Enrichment 
# -------------------------

enrichr.list <- list()

for (i in 1:length(dgeResults)){
  .res <- dgeResults[[i]]
  up.genes   <- row.names(.res[which(.res$log2FoldChange > 0 & .res$padj < padj.cutoff),])
  down.genes <- row.names(.res[which(.res$log2FoldChange < 0 & .res$padj < padj.cutoff),])
  both.genes <- row.names(.res[which(.res$padj < padj.cutoff),])
  enrichr.list[[i]] <- lapply(list(up.genes,down.genes,both.genes),function(x) {
    enrichR::enrichr(genes = x, databases = enrich.databases)
      })  
  print(paste("> Enriched: ", enrichr.list[[i]]))
}
names(enrichr.list) <- names(dgeResults)

# -----------------------------
# Write excels files
# -----------------------------

for (i in 1:length(dgeResults)){
  for (j in c("up","down","both")){
    filename = paste(
      file.path(smkout$dir, names(dgeResults)[[i]]),
      j,
      ".csv",
      sep="_")
    print(paste("filename: ", filename))
    #write.xlsx(x=enrichr.list[[names(dgeResults)[i]]][[j]],file=filename)
    #write.csv(x=enrichr.list[[names(dgeResults)[i]]][[j]], file=filename, row.names=FALSE)
    write.csv(x=enrichr.list[[names(dgeResults)[i]]][[j]], file=filename, row.names=FALSE)
  }
}

