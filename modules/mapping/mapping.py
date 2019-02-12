def mapping__alignerDft():
  return 'aligner'

def mapping__aligner():
  try:
    return pipeman.config.pipeline.modules.mapping.aligner.name
  except:
    pipeman.log.error("No aligner found in pipeline configuration.")

def mapping__alignerDir():
  aligner = mapping__aligner()
  if aligner:
    return aligner
  else:
    return mapping__alignerDft()
    
def mapping__alignerModule():
  aligner = mapping__aligner()
  module = ""
  if aligner:
    module = '{}.sk'.format(aligner)
  return module

def mapping__includeAlignerModule():
  aligner = mapping__aligner()
  if aligner:
    include: mapping__alignerModule()

@cluster__prefixMountPoint
def mapping__genomeIndex():
  """
  Retrieves the genome index using cluster and project metadata parameters.
  Uses 
   - cluster.genome_dir
   - project.genome .gencode and .species
  """
  return os.path.join(
    "{cluster.genome_dir}",
    "{genome.name}",
    "{aligner.command}").format(
      cluster  = pipeman.config.cluster,
      genome   = pipeman.config.project.genome,
      aligner  = pipeman.config.pipeline.modules.mapping[mapping__aligner()]
    )
