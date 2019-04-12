def gencode__gtfTemplateName():
  return "gencode.v{genome.gencode.version}.{genome.gencode.annotation_type}.gtf.gz"

@formatGenome
def gencode__gtf():
  return os.path.join(
    genome__annotationDir(),
    gencode__gtfTemplateName())

@formatGenome
def gencode__gtfUrl():
  return os.path.join(
    "ftp://ftp.ebi.ac.uk/pub/databases/gencode",
    "Gencode_{genome.species.common_name}",
    "release_{genome.gencode.version}",
    gencode__gtfTemplateName())
