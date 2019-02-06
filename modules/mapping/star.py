def star__readsToString(R1=[], R2=[]):
  """  
  Takes arrays of reads 1 and 2.
  Builds the input string for Star's readFilesIn paramter. 
  """
  return "{R1} {R2}".format(
    R1=','.join(R1), 
    R2=','.join(R2))

pipeman.includeModule('cluster/cluster.py')
@cluster__prefixMountPoint
def star__genomeIndex():
  """
  Retrieves the genome index using cluster and project metadata parameters.
  Uses 
   - cluster.genome_dir
   - project.genome .gencode and .species
  """
  return os.path.join(
    "{cluster.genome_dir}/gencode",
    "{genome.species.ensembl_name}",
    "{genome.gencode.version}", 
    "{genome.gencode.genome_version}"
      + ".{gen_type}"
      + ".star_index",
    "{star.version}").format(
      cluster  = pipeman.config.cluster,
      genome   = pipeman.config.project.genome,
      gen_type = pipeman.config.project.genome.gencode.annotation_type.rstrip('.annotation'),
      star     = pipeman.config.pipeline.modules.mapping.star,
    )
  
    
