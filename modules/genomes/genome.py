@cluster__prefixMountPoint
def genome__dir():
  return os.path.join(
    pipeman.config.cluster.genomeDir,
    project__speciesGenome(pipeman.config.project).genome.assembly.ucscRef)

def genome__fasta():
  """
  Retrieves the genome fastq using cluster and project metadata parameters.
  """
  return os.path.join(
    genome__dir(),
    "fa",
    project__speciesGenome(pipeman.config.project).genome.assembly.ucscRef + ".fa")

def genome__index():
  """
  Retrieves the genome index using cluster and project metadata parameters.
  """
  return os.path.join(
    genome__dir(),
    pipeman.config.pipeline.modules.mapping.aligner.name
  )

def genome__annotationDir():
  return os.path.join(
    genome__dir(),
    "annotation")

def genome__formatSpecies(func):
  def wrapper(*args, **kwargs):
    try:
      species = project__speciesGenome(pipeman.config.project)
    except:
      pipeman.log.error("Missing species in project configuration.")
    return func(*args, **kwargs).format(species=species)
  return wrapper
