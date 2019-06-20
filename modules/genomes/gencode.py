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
