smkSource("dge/deseq2.R")
dir.create(smkout$dir, showWarnings=FALSE)

library(enrichR)
#library(xlsx)
databases <- listEnrichrDbs()

# Parameter of the pipeline that defines the databases to make the enrichment of
enrich.databases <- c("GO_Biological_Process_2018",
                      "GO_Cellular_Component_2018",
                      "GO_Molecular_Function_2018",
                      "Reactome_2016",
                      "KEGG_2016",
                      "WikiPathways_2016",
                      "BioCarta_2016")

padj.cutoff = 0.1 

print(paste("> dgeResults: ", dgeResults))
print(paste("> names dgeResults: ", names(dgeResults)))

enrichr.list <- list()

print("Enrichment")
print(c("enrichr.list: ", enrichr.list))
for (i in 1:length(dgeResults)){
  print(paste("> dgeResults Nb. ", i))
  .res <- dgeResults[[i]]
  up.genes   <- row.names(.res[which(.res$log2FoldChange > 0 & .res$padj < padj.cutoff),])
  down.genes <- row.names(.res[which(.res$log2FoldChange < 0 & .res$padj < padj.cutoff),])
  both.genes <- row.names(.res[which(.res$padj < padj.cutoff),])
  print(paste("> both genes: ", both.genes))
  enrichr.list[[i]] <- lapply(list(up.genes,down.genes,both.genes),function(x) {
    enrichR::enrichr(genes = x, databases = enrich.databases)
      })  
  print(paste("> Enriched: ", enrichr.list[[i]]))
}
names(enrichr.list) <- names(dgeResults)

print(paste("> names enrichr: ", names(enrichr.list)))
#names(enrichr.list$condition_treated_vs_ctrl) = c("up","down","both")
names(enrichr.list[[1]]) = c("up","down","both")
print(paste("> enrichr: ", enrichr.list))

# Writes an 3 excels for each contrasts, "up", "down", "both" with the enrichment libraries in different excel tabs.

print(c("length(dgeResults): ", length(dgeResults)))
for (i in 1:length(dgeResults)){
  for (j in c("up","down","both")){
    print(paste("dir: ", smkout$dir))
    #filename = paste(names(dgeResults)[[i]],j,"enrichR_results.xlsx",sep="_")
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
