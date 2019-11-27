smkSource("clustering/rpkm.R")

suppressMessages(library("RColorBrewer"))
suppressMessages(library("pheatmap"))
suppressMessages(library("ggplot2"))


# ------------------
# Plotting Heatmap
# ------------------
annotation_column <- metadata[,2:dim(metadata)[2]]
row.names(annotation_column) <- metadata[,1]
colors <- colorRampPalette( rev(brewer.pal(11, "RdYlBu")) )(255)

grDevices::pdf(smkout$heatmap)
# fCountsRPKM_MV contains the N most variable feature as evaluated in rpkm.R
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

