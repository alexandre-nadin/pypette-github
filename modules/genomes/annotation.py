def annot__dir():
  return os.path.join(
    genome__dir(),
    "annotation")

@genome__formatSpecies
def annot__releaseDir():
  return os.path.join(
    annot__dir(),
    "{species.genome.assembly.release}")

def annot__indexDir():
  """
  Retrieves the genome index using cluster and project metadata parameters.
  """
  return os.path.join(
    annot__releaseDir(),
    pipeman.config.pipeline.modules.mapping.aligner.name)

# ----------------------
# EBI Annotation Files
# ----------------------
@genome__formatSpecies
def annot__ebiBaseName():
  return pipeman.config.databases.ebi.gencodeBaseName

@genome__formatSpecies
def annot__ebiGtfUrl():
  return os.path.join(
    pipeman.config.databases.ebi.gencodeUrl,
    annot__ebiBaseName() + ".gtf.gz")

def annot__ebiBase():
  return os.path.join(
    annot__releaseDir(),
    annot__ebiBaseName())

def annot__ebiGtf():
  return annot__ebiBase() + ".gtf.gz"

def annot__ebiBiotypes():
  return annot__ebiBase() + ".biotypes.tsv.gz"

def annot__ebiBed():
  return annot__ebiBase() + ".bed"

# -----------------------
# UCSC Annotation Files
# -----------------------
@genome__formatSpecies
def annot__ucscBaseName():
  return pipeman.config.databases.ucsc.gencodeBaseName

@genome__formatSpecies
def annot__ebiTxtUrl():
  return os.path.join(
    pipeman.config.databases.ucsc.gencodeUrl,
    annot__ucscBaseName() + ".txt.gz")

def annot__ucscBase():
  return os.path.join(
    annot__releaseDir(),
    annot__ucscBaseName())

def annot__ucscTxt():
  return annot__ucscBase() + ".txt.gz"

def annot__ucscGenePred():
  return annot__ucscBase() + ".genePred.gz"

def annot__ucscBedgz():
  return annot__ucscBase() + ".bed.gz"

def annot__ucscBed():
  return annot__ucscBase() + ".bed"
