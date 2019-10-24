def genome__formatSpecies(func):
  def wrapper(*args, **kwargs):
    try:
      species = project__speciesGenome(pipeman.config.project)
    except:
      pipeman.log.error("Missing species in project configuration.")
    return func(*args, **kwargs).format(species=species)
  return wrapper

@genome__formatSpecies
@cluster__prefixMountPoint
def genome__dir():
  return os.path.join(
    pipeman.config.cluster.genomeDir,
    "{species.genome.assembly.ucscRef}")

@genome__formatSpecies   
def genome__fasta():
  """
  Retrieves the genome fastq using cluster and project metadata parameters.
  """
  return os.path.join(
    genome__dir(),
    "fa",
    "{species.genome.assembly.ucscRef}.fa")
