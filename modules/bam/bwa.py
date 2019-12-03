def bam_bwa__readsToString(R1=[], R2=[]):
  return "{R1} {R2}".format(
    R1 = "<(zcat {})".format(" ".join(R1)) if R1 else "",
    R2 = "<(zcat {})".format(" ".join(R2)) if R2 else ""
  )

def bam_bwa__indexDir(**kwargs):
  return os.path.join(
    annot__dir(**kwargs),
    "bwa")
  
@genome__formatSpeciesCfg
def bam_bwa__indexPrefix(**kwargs):
  return os.path.join(
    bam_bwa__indexDir(),
    "{species.genome.assembly.ucscRef}")
