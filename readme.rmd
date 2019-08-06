pypette | pipette | pipew (workflow) | piped (data) | pipeg (genomics)

pypette is a collection of tools that allows to process and analyze genomic data using standard pipelines. It is aimed at producing automatic standard analysis and data processes, saving time for both the wet lab and bioinformaticians while retaining clarity and reproducibility in the data processing workflow. It relies on a pipeline manager (pipeman) that uses Snakemake [REF]. The pipeman deals with configuration files and allows to build clear and flexible Snakemake rules and targets.

CTGB Quick Run
  CTGB's Shell Environment
  Start pipelines
  
Targets
  Introduction 
  Querying a simple bam file
  Target Syntax
  
Pipeline Configuration
  Base directory
  Config files
  Samples
      
Pipelines
  Rnaseq
    Configuration
    QC
    Biotypes
    
  Dna
    Configuration
    QC
  scRna
    Configuration
  Seqrun
    Configuration
    QC
    Demultiplexing
