def genome__formatSpeciesCfg(func):
  def wrapper(*args, **kwargs):
    try:
      species = project__speciesGenome()
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

def ensembl__buildVersion():
  species = project__speciesGenome()
  ensemblRelease = pipeman.config.species[species].genome.assembly.ensemblRelease
  buildName = pipeman.config.species[species].genome.assembly.buildName
  return f"{buildName}.{ensemblRelease}"

def genome__gatkDir():
  return os.path.join(
    genome__dir(),
    "GATK_pypette")

def genome__baseRecalibSitesBasenames(gnmName):
  return [
    f"resources-broad-{gnmName}-v0-1000G_phase1.snps.high_confidence.vcf.gz",
    f"resources-broad-{gnmName}-v0-Mills_and_1000G_gold_standard.indels.vcf.gz",
    f"dbsnp_current.{gnmName}.vcf.gz" 
  ]

def genome__baseRecalibSites(gnmName):
  return [ f"{genome__gatkDir()}/{site}"
           for site in genome__baseRecalibSitesBasenames(gnmName)
         ]
  

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
