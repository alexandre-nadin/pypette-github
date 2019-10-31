def genome__formatSpeciesCfg(func):
  def wrapper(*args, **kwargs):
    try:
      species = project__speciesGenome(pipeman.config.project)
    except:
      pipeman.log.error("Missing species in project configuration.")
    return func(*args, **kwargs).format(species=species)
  return wrapper

@genome__formatSpeciesCfg
@cluster__prefixMountPoint
def genome__dir():
  return os.path.join(
    pipeman.config.cluster.genomeDir,
    "{species.genome.assembly.ucscRef}")

# -------------
# Fasta Files
# -------------
@genome__formatSpeciesCfg   
def genome__fastaBase():
  return os.path.join(
    genome__dir(),
    "fa",
    "{species.genome.assembly.ucscRef}")

def genome__fasta():
  """ Produces the species' genome fasta. """
  return f"{genome__fastaBase()}.fa"

def genome__fastaIdx():
  """ Produces the species' genome fasta. """
  return f"{genome__fasta()}.fai"

# -----------
# 2bit Files
# -----------
@genome__formatSpeciesCfg   
def genome__2bitBase():
  return os.path.join(
    genome__dir(), 
    "2bit", 
    "{species.genome.assembly.ucscRef}")

def genome__2bit():
  """ Produces the species' genome 2bit. """
  return f"{genome__2bitBase()}.2bit"

@genome__formatSpeciesCfg
def genome__ucsc2bitUrl():
  return pipeman.config.databases.ucsc.tbitUrl
