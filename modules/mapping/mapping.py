def mapping__setAligner(name):
  workflow.globals[mapping__alignerVarName()] = name

def mapping__alignerDft():
  return 'aligner'

def mapping__alignerVarName():
  return '_mapping__aligner'

def mapping__getAligner():
  if not mapping__alignerVarName() in workflow.globals.keys():
    mapping__setAligner(mapping__alignerDft())
  return workflow.globals[mapping__alignerVarName()]

def mapping__aligner():
  mappingKeys = list(pipeman.config.pipeline.modules.mapping.keys())
  if mappingKeys:
    return mappingKeys[0]
  else:
    pipeman.log.error("No aligner found in pipeline configuration.")
    raise

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
