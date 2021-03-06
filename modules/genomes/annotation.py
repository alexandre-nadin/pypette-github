def annot__dir(**kwargs):
  return os.path.join(
    genome__dir(**kwargs),
    "annotation")

@genome__formatSpeciesCfg
def annot__gencodeDir(**kwargs):
  return os.path.join(
    annot__dir(**kwargs),
    "{species.genome.assembly.gencodeRelease}")

# ----------------------
# EBI Annotation Files
# ----------------------
@genome__formatSpeciesCfg
def annot__ebiBaseUrl():
  return pypette.config.databases.ebi.gencodeBaseName

@genome__formatSpeciesCfg
def annot__ebiGtfUrl():
  return os.path.join(
    genome__ebiReleaseUrl(),
    annot__ebiBaseUrl() + ".gtf.gz")

def annot__ebiBase(**kwargs):
  return os.path.join(
    annot__gencodeDir(**kwargs),
    "ebi",
    annot__ebiBaseUrl())

def annot__ebiGtf(**kwargs):
  return annot__ebiBase(**kwargs) + ".gtf"

def annot__ebiGtfGz(**kwargs):
  return annot__ebiGtf(**kwargs) + ".gz"

def annot__ebiBiotypes():
  return annot__ebiBase() + ".biotypes.tsv.gz"

def annot__ebiBed():
  return annot__ebiBase() + ".bed"

# -----------------------
# UCSC Annotation Files
# -----------------------
@genome__formatSpeciesCfg
def annot__ucscBaseUrl():
  return pypette.config.databases.ucsc.gencodeBaseName

@genome__formatSpeciesCfg
def annot__ucscTxtUrl():
  return os.path.join(
    pypette.config.databases.ucsc.gencodeUrl,
    annot__ucscBaseUrl() + ".txt.gz")

def annot__ucscBase(**kwargs):
  return os.path.join(
    annot__gencodeDir(**kwargs),
    "ucsc",
    annot__ucscBaseUrl())

def annot__ucscTxt(**kwargs):
  return annot__ucscBase(**kwargs) + ".txt.gz"

def annot__ucscGenePred(**kwargs):
  return annot__ucscBase(**kwargs) + ".genePred.gz"

def annot__ucscGtf(**kwargs):
  return annot__ucscBase(**kwargs) + ".gtf"

def annot__ucscGtfGz(**kwargs):
  return annot__ucscGtf(**kwargs) + ".gz"

def annot__ucscBedgz(**kwargs):
  return annot__ucscBase(**kwargs) + ".bed.gz"

def annot__ucscBed():
  return annot__ucscBase() + ".bed"
