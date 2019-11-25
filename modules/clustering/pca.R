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

# PCA parameters
pcx = 1
pcy = 2
centering = TRUE
scaling = TRUE

# Performing PCA
pca = prcomp(t(fCountsRPKM_MV), center=centering, scale=scaling)
var = round(matrix(((pca$sdev^2)/(sum(pca$sdev^2))), ncol=1)*100,1)
score = as.data.frame(pca$x)
# Plot paramters
xlab = paste("PC", pcx, " (",var[pcx],"%)", sep="")
ylab = paste("PC", pcy, " (",var[pcy],"%)", sep="")

# ------------
# PLOT PCA
# -----------
grDevices::pdf(smkout$pca)
# plot a PCA plot for any on the factor in the metadata 
for (col in 2:dim(metadata)[2]) {
	score$factor <-  metadata[,col]
	print(ggplot(score, aes(x=score[,pcx], y=score[,pcy], color=factor))+
		geom_point(size=3)+
		labs(x=xlab, y=ylab, title=paste("PC",pcx," vs PC",pcy," for factor ",colnames(metadata)[col],sep="")) +   
		  geom_hline(yintercept=0, linetype="dashed", color = "grey") +
		  geom_vline(xintercept=0, linetype="dashed", color = "grey") +
		  theme(plot.title = element_text(color="blue", size=16, face="bold.italic"),
		        axis.title.x = element_text(color="#993333", size=14, face="bold"),
		        axis.text.x = element_text(face = "bold", color = "black", size = 12),
		        axis.title.y = element_text(color="#993333", size=14, face="bold"),
		        axis.text.y = element_text(face = "bold", color = "black", size = 12),
		        legend.position="bottom", 
		        panel.background = element_rect(fill = "white",colour = "black", size = 1, linetype = "solid"), 
		        panel.grid.major = element_line(size = 0.25, linetype = 'solid', colour = "grey"), 
		        panel.grid.minor = element_line(size = 0.125, linetype = 'solid', colour = "grey"))) 

}
dev.off()

