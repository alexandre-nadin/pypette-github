def exome__targetDir(**kwargs):
  return os.path.join(
    annot__dir(**kwargs),
    "exomes_targets")

def exome__intervalListFmt(**kwargs):
  return os.path.join(
    exome__targetDir(**kwargs),
    "agilent_v7_sureselect_{}.interval_list")

def exome__targetIntervals(**kwargs):
  return exome__intervalListFmt(**kwargs).format("Regions")

def exome__baitIntervals(**kwargs):
  return exome__intervalListFmt(**kwargs).format("MergedProbes")

