def formatGenome(func):
  def wrapper(*args, **kwargs):
    return func(*args, **kwargs).format(
        genome = pipeman.config.project.genome)
  return wrapper

@cluster__prefixMountPoint
def genome__dir():
  return os.path.join(
    pipeman.config.cluster.genomeDir,
    pipeman.config.project.genome.name
  )

def genome__fasta():
  """
  Retrieves the genome fastq using cluster and project metadata parameters.
  """
  return os.path.join(
    genome__dir(),
    "fa",
    pipeman.config.project.genome.name + ".fa"
  )

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

