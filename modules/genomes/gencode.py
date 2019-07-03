def gencode__baseName():
  return "gencode.v{genome.gencode.version}.{genome.gencode.annotation_type}"

# -----------
# GTF Files
# -----------
def gencode__gtfTemplate():
  return gencode__baseName() + ".gtf.gz"

@formatGenome
def gencode__gtf():
  return os.path.join(
    genome__annotationDir(),
    gencode__gtfTemplate())

@formatGenome
def gencode__gtfUrl():
  return os.path.join(
    "ftp://ftp.ebi.ac.uk/pub/databases/gencode",
    "Gencode_{genome.species.common_name}",
    "release_{genome.gencode.version}",
    gencode__gtfTemplate())

def formatUcscAnnot(func):
  def wrapper(*args, **kwargs):
    return func(*args, **kwargs).format(
        genome = pipeman.config.project.genome,
        annotationType = pipeman.config.project.genome.gencode.annotation_type
           .split('.annotation')[0].lower().capitalize())
  return wrapper

@formatUcscAnnot
def gencode__ucscAnnotUrl():
  return os.path.join(
    pipeman.config.databases.ucsc.gencodeUrl,
    pipeman.config.databases.ucsc.gencodeBaseName + "txt.gz")

# ----------
# Bed Files
# ----------
def gencode__bedTemplate():
  return gencode__baseName() + ".bed"

@formatGenome
def gencode__bed():
  return os.path.join(
    genome__annotationDir(),
    gencode__bedTemplate())

# ---------------------
# Annot genePred Files
# ---------------------
@formatUcscAnnot
def gencode__ucscAnnotBaseName():
  return os.path.join(
    genome__annotationDir(),
    pipeman.config.databases.ucsc.gencodeBaseName)

def gencode__ucscGenePred():
  return gencode__ucscAnnotBaseName() + ".genePred"

def gencode__ucscBed():
  return gencode__ucscAnnotBaseName() + ".bed.gz"

def gencode__ucscAnnot():
  return gencode__ucscAnnotBaseName() + ".txt.gz"
