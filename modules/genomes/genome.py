def genome__formatSpeciesCfg(func):
  """
  Gets the string given by the :func: function and formats it with the
  configuration species.
  """
  def wrapper(*args, **kwargs):
    try:
      species = project__speciesGenome()
    except:
      pypette.log.error("Missing species in project configuration.")
    return func(*args, **kwargs).format(species=species)
  return wrapper

@genome__formatSpeciesCfg
def genome__baseDir(sharedDir=False, **kwargs):
  return pypette.config.cluster.genomeDir if sharedDir else "genomes"

@genome__formatSpeciesCfg
def genome__dir(**kwargs):
  return os.path.join(
    genome__baseDir(**kwargs),
    "{species.genome.assembly.ucscRef}")

def genome__speciesDir(**kwargs):
  return os.path.join(
    genome__baseDir(**kwargs),
    "{species.taxo}")

def ensembl__buildVersion():
  assembly = pypette.config.species[project__speciesGenomeName()].genome.assembly
  return f"{assembly.buildName}.{assembly.ensemblRelease}"

def genome__gatkDir(**kwargs):
  return os.path.join(
    genome__dir(**kwargs),
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
  
# ----------------
# Release version
# ----------------
@genome__formatSpeciesCfg
def genome__release():
  return "{species.genome.assembly.gencodeRelease}"
  
def genome__ebiDir(**kwargs):
  return os.path.join(
    genome__dir(**kwargs),
    "ebi")

def genome__ebiReleaseDir(**kwargs):
  return os.path.join(
    genome__ebiDir(**kwargs),
    genome__release())

def genome__ebiReleaseUrl():
  return os.path.join(
    pypette.config.databases.ebi.gencodeUrl,
    f"release_{genome__release()}")

# -------------
# Fasta Files
# -------------
def genome__fastaDir(**kwargs):
  return os.path.join(genome__dir(**kwargs), "fa")

## EBI
def genome__ebiFastaDir(**kwargs):
  return os.path.join(genome__fastaDir(**kwargs), "ebi")

@genome__formatSpeciesCfg
def genome__ebiFastaBase(**kwargs):
  return os.path.join(
    genome__ebiFastaDir(**kwargs),
    pypette.config.databases.ebi.gencodeFaBaseName)

def genome__ebiFasta(**kwargs):
  """ Produces the species' genome fasta. """
  return f"{genome__ebiFastaBase(**kwargs)}.fa"

def genome__ebiFastaGz(**kwargs):
  """ Produces the species' genome fasta. """
  return f"{genome__ebiFasta(**kwargs)}.gz"

def genome__ebiFastaIdx(**kwargs):
  """ Produces the species' genome fasta. """
  return f"{genome__ebiFastaBase(**kwargs)}.fai"

@genome__formatSpeciesCfg
def genome__ebiFastaUrl():
  return os.path.join(
    genome__ebiReleaseUrl(),
    pypette.config.databases.ebi.gencodeFa)

## UCSC 
def genome__ucscFastaDir(**kwargs):
  return os.path.join(genome__fastaDir(**kwargs), "ucsc")

@genome__formatSpeciesCfg
def genome__ucscFastaBase(**kwargs):
  return os.path.join(
    genome__ucscFastaDir(**kwargs),
    "{species.genome.assembly.ucscRef}")

def genome__ucscFasta(**kwargs):
  """ Produces the species' genome fasta. """
  return f"{genome__ucscFastaBase(**kwargs)}.fa"

def genome__ucscFastaIdx(**kwargs):
  """ Produces the species' genome fasta. """
  return f"{genome__ucscFastaBase(**kwargs)}.fai"


# -----------
# 2bit Files
# -----------
@genome__formatSpeciesCfg   
def genome__ucsc2bitBase(**kwargs):
  return os.path.join(
    genome__dir(**kwargs), 
    "2bit", 
    "{species.genome.assembly.ucscRef}")

def genome__ucsc2bit(**kwargs):
  """ Produces the species' genome 2bit. """
  return f"{genome__ucsc2bitBase(**kwargs)}.2bit"

@genome__formatSpeciesCfg
def genome__ucsc2bitUrl():
  return pypette.config.databases.ucsc.tbitUrl

# -------------
# Cell cycles
# -------------
@genome__formatSpeciesCfg                    
def genome__speciesCellCycleFile(**kwargs):
  return os.path.join(
    genome__speciesDir(**kwargs),
    "{species.taxo}_cell_cycle_genes.txt")
