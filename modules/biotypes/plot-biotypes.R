#!/usr/bin/Rscript
suppressMessages(library("limma"))
suppressMessages(library("edgeR"))
suppressMessages(library("GEOquery"))
suppressMessages(library("ggplot2"))
suppressMessages(library("RColorBrewer"))
  
biotypes_function <- function(countsFile,
                              biotypesFile, 
                              pngFolder = 'Biotypes_plots/', 
                              minSamples=0, 
                              filterExp=TRUE, 
                              useRpkm=FALSE, 
                              plotPie=TRUE,
                              sglSamplePlot=TRUE,
                              writeTable = TRUE,
                              perc2plot=0.01,
                              useGgplot= TRUE ) {  
  
  # read the counts on the merged counts file 
  # reads the annotation info from the counts of one sample
  import_counts <- read.delim(file = countsFile, header = T)
  annotation_info  <- import_counts[,1:6]
    if (ncol(import_counts)-6 ==1) {
    counts <- matrix(data=import_counts[,7:ncol(import_counts)], 
    nrow = nrow(import_counts), 
    ncol = ncol(import_counts)-ncol(annotation_info), 
    dimnames = list(annotation_info$Geneid,colnames(import_counts)[7:ncol(import_counts)]))
    } else {
    counts <- import_counts[,7:ncol(import_counts)]
    row.names(counts) <- annotation_info$Geneid
    }

  row.names(counts) <- annotation_info$Geneid 
  colnames(counts) = colnames(import_counts)[7:ncol(import_counts)]
  # dictionary from previos rule 
  dict <- read.delim(biotypesFile, header=FALSE)
  #n_s is the MIN_NUM_OF_EXPRESSED_SAMPLE
  n_s = minSamples
  dir.create(pngFolder, showWarnings = F, recursive = T)

  # save counts matrix and annotation in the DGElist object {require library edgeR}
  y.all <-DGEList(counts=counts, genes=annotation_info)

  # match row.names counts with dictionary genes
  ids = match(row.names(counts),dict[,1])
  # biolist is a list with the biotypes of the counted genes 
  biolist = dict[ids,2]
  # NAs filtering
  counts <- as.matrix(counts[!is.na(ids),])
  colnames(counts) <- colnames(import_counts)[7:ncol(import_counts)]
  biolist = biolist[!is.na(biolist)]
  y.all = y.all[!is.na(ids),]

  # count per milion in LOG scale {require library edgeR}
  cpm <- cpm(counts, log=T)

  # PLOT text and file names
  # when filterExp = F
  Mtext="All the genes have been considered" 
  # when useRpkm = F
  Main ="Biotypes distribution among samples, using raw counts"
  Main_pie = "PieChart of raw counts to biotypes"
  filename_writeTable = paste(pngFolder,"/biotypes_percentages_counts.txt", sep='')
  ylabel_opt = 'Counts'
  # use all genes
  isexpr = row.names(counts) == row.names(counts)

  # When filter EXP is T I include to the analysis just the expressed genes
  if (filterExp) {  
    # consider only the genes whose counts are more than 1cpm in at least n_s sample
    isexpr = rowSums(cpm(counts)>1) >= n_s
    # count how many genes pass this filter:
    nexp = sum(isexpr) 
    # update cpm
    #cpm <- cpm(counts[isexpr,], log=T)
    # update counts
    counts <- as.matrix(counts[isexpr,])
    colnames(counts) = colnames(import_counts)[7:ncol(import_counts)]
    # update Mtext
    Mtext=paste(nexp, " expressed genes have been considered\n", sep="")
  }
  # When useRpkm is T I use the rpkm instead of the counts 
  if (useRpkm) {
    rpkm = rpkm(y.all, log=F, gene.length=y.all$genes$Length)[isexpr,]
    # Here is the trick: I call 'counts' the rpkm values, 
    # in order to apply the same code on different data...like a flying cow
    counts = as.matrix(rpkm)
    colnames(counts) = colnames(import_counts)[7:ncol(import_counts)]
    #Update the plots' feature
    Main ="Biotypes distribution among samples, using RPKM"
    filename_writeTable = paste(pngFolder, "/biotypes_percentages_RPKM.txt", sep='')
    ylabel_opt = 'RPKM'
    Main_pie = "PieChart of RPKM to biotypes"
  }  
  
  #### MAIN PLOT: summary of biotypes in each sample  ####
  #the different biotypes are the levels of the list biolist 
  biotypes = levels(biolist)
  summary = c()
  # write in summary the sum of the different biotypes in any sample  
  for (i in 1:ncol(counts)) {
    t = counts[,i]
    s = unlist(lapply(biotypes, function (x) sum(t[which(biolist[isexpr]==x)])))
    summary = cbind(summary, s)
  }
  colnames(summary) = colnames(counts) # samples
  rownames(summary) = biotypes 
  colors=colorRampPalette(c("red","green","blue","yellow","black","orange","pink","grey"))(length(biotypes))
  # show just the biotypes represented more than perc2plot 
  exp = rowSums(summary)/sum(summary)> perc2plot 
  leg = biotypes[exp]
  legcol = colors[exp]
  yleg = max(colSums(summary))/4
  png_summary_file = paste(pngFolder,'/biotypes_summary.png',sep = '')
  png(png_summary_file, width=1600, height=1200, pointsize=20)
  par(xpd=TRUE, mar=c(20,5,10,3))
  barplot(summary, main=Main, col=colors, cex.axis=1.3, las=1, names.arg=colnames(summary), cex=1.3, las=2, bty="L")
  mtext(Mtext)
  legend(x=0, y=-yleg*2.5 , legend=leg, fill=legcol, horiz=F, ncol=3, cex=1.3, bty="n")
  dev.off()
  # plot using ggplot
  if (useGgplot) { 
    png_file_summary_ggplot = paste(pngFolder,'/biotypes_summary_ggplot.png',sep = '')
    my_biotypes<- rep(biotypes,ncol(summary))
    my_exp <- rep(exp,ncol(summary))
    my_count_tot=c(summary[,1])
    my_samplename=rep(colnames(summary)[1],length(biotypes))
    if (ncol(summary)> 1) {
      for (i in 2:ncol(summary)) {
      my_count_tot = c(my_count_tot, summary[,i])
      my_samplename = c(my_samplename, rep(colnames(summary)[i],length(biotypes)))
      }
    }
  my_data = data.frame(biotype = my_biotypes, sample= my_samplename, count = my_count_tot, exp=my_exp)
  colourCount = length(unique(my_data[my_data$exp,]$biotype))
    barp=ggplot(my_data[my_data$exp,], aes(x=sample, y=count, fill = biotype)) + 
      geom_bar(stat="identity", width=0.8 ) + 
      scale_fill_brewer(palette="Spectral") + 
      scale_fill_manual(values = colorRampPalette(brewer.pal(11, "Spectral"))(colourCount)) +
      labs(title=Main, subtitle = Mtext, x = "Samples", y= ylabel_opt, fill = paste('Biotypes >',perc2plot*100,'%')) +
      theme(axis.text.x = element_text(angle = 0, face = "bold", color = "#999999", size=10), axis.text.y = element_text(angle = 0, face = "bold", color = "#999999", size=10), 
      panel.background = element_rect(fill = "white",colour = "black", size = 1, linetype = "solid"), 
      panel.grid.major = element_line(size = 0.5, linetype = 'solid', colour = "grey"), panel.grid.minor = element_line(size = 0.25, linetype = 'solid', colour = "grey"))  
    ggsave(png_file_summary_ggplot, barp, width = 8, height = 7)
  }

  # total boxplot
  cpm <- as.matrix(cpm[isexpr,])
  png_file = paste(pngFolder, "/biotypes_boxplot.png", sep="")
  png(png_file, width=1600, height=1200, pointsize=20)
  par(mar=c(16,5,7,7))
   boxplot(ylab="log2NormalizedExpression", 
    cpm~biolist[isexpr], 
    names=levels(biolist[isexpr]),
    las=2,
    cex.axis=1,
    main="Biotypes distribution",
    cex=0.5)
  mtext(Mtext)
  dev.off()

  # ggplot
  if (useGgplot) {
    png_file_biotypes_ggplot = paste(pngFolder, "/biotypes_boxplot_ggplot.png", sep="") 
    cpm_biolist = data.frame(cpm = rowMeans(cpm), biotypes = biolist[isexpr])
    boxp = ggplot(cpm_biolist, aes(x=biotypes, y = cpm)) + 
           geom_boxplot(colour="black", fill = "#56B4E9") + 
           theme(
             axis.text.x = element_text(angle = 90, face = "bold", color = "#999999", size=8, hjust =1), 
             axis.text.y = element_text(angle = 0,  face = "bold", color = "#999999", size=8),
             panel.background = element_rect(fill = "white", colour = "black", size = 1, linetype = "solid"),
             panel.grid.major = element_line(size = 0.50, linetype = 'solid', colour = "grey"), 
             panel.grid.minor = element_line(size = 0.25, linetype = 'solid', colour = "grey")) + 
           labs(
             title='Biotypes distribution',
             subtitle = Mtext,
             x = "Biotypes",
             y = "log2NormalizedExpression" )
    ggsave(png_file_biotypes_ggplot, boxp, width = 8, height = 7)
  }

  # plot also graphs for single sample 
  if (sglSamplePlot) { 
    for (i in 1:ncol(counts)) {
      png_file = paste(pngFolder, "/biotypes_boxplot_for_",colnames(counts)[i],".png", sep="")
      png(png_file, width=1600, height=1200, pointsize=20)
      par(mar=c(16,5,7,7))
      boxplot(
        ylab="log2NormalizedExpression",
        cpm[,i]~biolist[isexpr],
        names=levels(biolist[isexpr]),
        las=2,
        cex.axis=1,
        main=paste("Biotypes distribution in sample ",colnames(counts)[i],sep=""),
        cex=0.3)
      dev.off()

      if (useGgplot) {
        png_file_biotypes_ggplot_tmp = paste(pngFolder, "/biotypes_boxplot_", colnames(counts)[i], "_ggplot.png", sep="")
        cpm_biolist = data.frame(cpm = cpm[,i] , biotypes = biolist[isexpr])
        boxp_tmp = ggplot(cpm_biolist, aes(x=biotypes, y = cpm))  +
                   geom_boxplot(colour="black", fill = "#56B4E9") + 
                   theme(
                     axis.text.x = element_text(angle = 90, face = "bold", color = "#999999", size=8, hjust =1), 
                     axis.text.y = element_text(angle = 0, face = "bold", color = "#999999", size=8),
                     panel.background = element_rect(fill = "white",colour = "black", size = 1, linetype = "solid"),
                     panel.grid.major = element_line(size = 0.5, linetype = 'solid', colour = "grey"), 
                     panel.grid.minor = element_line(size = 0.25, linetype = 'solid', colour = "grey")) +
                   labs(
                     title= paste("Biotypes distribution in sample ", colnames(counts)[i], sep=""),
                     subtitle = Mtext,
                     x = "Biotypes",
                     y = "log2NormalizedExpression")
        ggsave(png_file_biotypes_ggplot_tmp, boxp_tmp, width = 8, height = 7)
      }
    }
  }
  
  if (plotPie) {
    biotypes = levels(biolist)
    pp = unlist(lapply(biotypes, function (x) sum(counts[which(biolist[isexpr]==x),])))
    names(pp)= biotypes
    colors=colorRampPalette(c("red","green","blue","yellow","black","orange","pink","grey"))(length(pp))
    png_file = paste(pngFolder, "/biotypes_pie.png", sep="")
    png(png_file,width=1400,height=1800,pointsize=20)
    par(mar=c(10,3,3,3),xpd=T)
    pie(pp,
        col=colors,
        labels=ifelse(pp/sum(pp)>0.01,names(pp),""), 
        main=Main_pie)
    legend(x=-1.1, y=-0.9, legend=biotypes, fill=colors, horiz=F, ncol=3)
    dev.off()
    if (useGgplot) { 
      png_file_biotypes_ggplot_pie = paste(pngFolder, "/Biotypes_pie_ggplot.png", sep="")
      pp_plot = as.data.frame(pp)
      pp_plot$biotype = row.names(pp_plot)
      pp_plot$perc = pp/sum(pp)
      pie = ggplot(
              pp_plot[pp_plot$perc > perc2plot,], 
              aes(x = '', y = perc*100, fill = biotype )) + 
            geom_bar(stat = 'identity')                   +
            coord_polar("y", start=0)                     +
            labs(
              title="Biotypes Pie plot", 
              subtitle=Mtext, 
              x = '', 
              y= "Biotypes %", 
              fill = paste('Biotypes >', perc2plot*100, '%')) + 
            theme(
              axis.text.x = element_text(face = "bold", color = "black", size=14),
              panel.background = element_rect(fill = "white", colour = "black", size = 0.5, linetype = "solid"))
      ggsave(png_file_biotypes_ggplot_pie, pie, width = 8, height = 7)
    }

    # Single pie for single sample
    if (sglSamplePlot) {
      summary = c()
      for (i in 1:ncol(counts)) {
        t = counts[,i]
        s = unlist(lapply(biotypes, function (x) sum(t[which(biolist[isexpr]==x)])))
        summary = cbind(summary, s)
      }
      colnames(summary) = colnames(counts)
      rownames(summary) = biotypes
      exp = rowSums(summary)/sum(summary)> perc2plot

      nplot = ncol(summary)
      for (i in 1:nplot) {
        png_file = paste(pngFolder, "/biotypes_pie_", colnames(summary)[i], ".png", sep="")
        png(png_file, width=1600, height=1600, pointsize=20)
        pie(summary[,i], col=colors, labels=ifelse(summary[,i]/sum(summary[,i])>perc2plot,names(summary[,i]),""), radius=0.8, main=colnames(summary[,i]))
        dev.off()
      }
    }
  }
  
  if (writeTable) {
    percent=t(t(summary)/colSums(summary))*100
    write.table(percent,filename_writeTable, row.names=T, col.names=T, quote=F, sep="\t")
  }

  return()
}


# ---------------------
# Snakemake parameters
# ---------------------
smkp   <- snakemake@params
smkin  <- snakemake@input
smkout <- snakemake@output

biotypes_function(
  countsFile    = smkin$counts,
  biotypesFile  = smkin$biotypes,
  pngFolder     = smkout$dir,
  minSamples    = smkp$biotypes$minSamples,
  filterExp     = smkp$biotypes$filterExp,
  useRpkm       = smkp$biotypes$useRpkm,
  plotPie       = smkp$biotypes$plotPie,
  sglSamplePlot = smkp$biotypes$sglSamplePlot,
  writeTable    = smkp$biotypes$writeTable,
  perc2plot     = smkp$biotypes$perc2plot,
  useGgplot     = smkp$biotypes$useGgplot)
