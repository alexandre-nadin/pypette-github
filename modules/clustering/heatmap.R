suppressMessages(library("edgeR"))
suppressMessages(library(data.table)) 
suppressMessages(library("RColorBrewer"))
suppressMessages(library("ggplot2"))


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

# import metadata
metadata = read.delim(smkin$metadata, header=TRUE)
# Reordering counts matrix to have samples ordered as in metadata
fCountsData <- fCountsData[,match(metadata[,1], colnames(fCountsData))] # assuming that the first column in metadata is sample name

# Calculate RPKM
y = DGEList(counts=fCountsData, genes = fCountsAnnotation)
# filter on expression
keep <- rowSums(cpm(y)> 1) >= smkp$dge$minSamples
fCountsRPKM = rpkm(y, log=T, gene.length =y$genes$Length)
# evaluate pca only for the N most variable genes 
N = 500
vary <- apply(fCountsRPKM[keep,],1,var)
NMostVariable <- names(sort(vary, decreasing = T)[1:N])
fCountsRPKM_MV <- fCountsRPKM[NMostVariable,]

# Plotting Heatmap
annotation_column <- metadata[,2:dim(metadata)[2]]
row.names(annotation_column) <- metadata[,1]
colors <- colorRampPalette( rev(brewer.pal(11, "RdYlBu")) )(255)

grDevices::pdf(smkout$heatmap)
print(pheatmap::pheatmap(fCountsRPKM_MV, 
			cluster_rows = TRUE, 
			cluster_cols = TRUE, 
			main = paste('Heatmap of the',N,'most variable genes', sep =' '),
			show_rownames = FALSE,
			annotation_col = annotation_column,
			fontsize = 12, 
			fontsize_row = 10, 
			fontsize_col = 14, 
			display_numbers = FALSE, 
			col=colors)
)
dev.off()

