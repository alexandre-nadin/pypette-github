smkSource("clustering/rpkm.R")

suppressMessages(library("RColorBrewer"))
suppressMessages(library("ggplot2"))

# ------------------
# PCA parameters
# ------------------
pcx = 1
pcy = 2
centering = TRUE
scaling = TRUE

# ------------------
# Performing PCA
# ------------------
# fCountsRPKM_MV contains the N most variable feature as evaluated in rpkm.R
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

