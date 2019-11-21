def annot__dir():
  return os.path.join(
    genome__dir(),
    "annotation")

@genome__formatSpeciesCfg
def annot__gencodeDir():
  return os.path.join(
    annot__dir(),
    "{species.genome.assembly.gencode}")

# ----------------------
# EBI Annotation Files
# ----------------------
@genome__formatSpeciesCfg
def annot__ebiBaseUrl():
  return pipeman.config.databases.ebi.gencodeBaseName

@genome__formatSpeciesCfg
def annot__ebiGtfUrl():
  return os.path.join(
    pipeman.config.databases.ebi.gencodeUrl,
    annot__ebiBaseUrl() + ".gtf.gz")

def annot__ebiBase():
  return os.path.join(
    annot__gencodeDir(),
    "ebi",
    annot__ebiBaseUrl())

def annot__ebiGtf():
  return annot__ebiBase() + ".gtf"

def annot__ebiGtfGz():
  return annot__ebiGtf() + ".gz"

def annot__ebiBiotypes():
  return annot__ebiBase() + ".biotypes.tsv.gz"

def annot__ebiBed():
  return annot__ebiBase() + ".bed"

# -----------------------
# UCSC Annotation Files
# -----------------------
@genome__formatSpeciesCfg
def annot__ucscBaseUrl():
  return pipeman.config.databases.ucsc.gencodeBaseName

@genome__formatSpeciesCfg
def annot__ebiTxtUrl():
  return os.path.join(
    pipeman.config.databases.ucsc.gencodeUrl,
    annot__ucscBaseUrl() + ".txt.gz")

def annot__ucscBase():
  return os.path.join(
    annot__gencodeDir(),
    "ucsc",
    annot__ucscBaseUrl())

def annot__ucscTxt():
  return annot__ucscBase() + ".txt.gz"

def annot__ucscGenePred():
  return annot__ucscBase() + ".genePred.gz"

def annot__ucscGtf():
  return annot__ucscBase() + ".gtf"

def annot__ucscGtfGz():
  return annot__ucscGtf() + ".gz"

def annot__ucscBedgz():
  return annot__ucscBase() + ".bed.gz"

def annot__ucscBed():
  return annot__ucscBase() + ".bed"
