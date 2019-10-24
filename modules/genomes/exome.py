def exome__targetDir():
  return os.path.join(
    annot__dir(),
    "exomes_targets")

def exome__intervalListFmt():
  return os.path.join(
    exome__targetDir(),
    "agilent_v7_sureselect_{}.interval_list")

def exome__targetIntervals():
  return exome__intervalListFmt().format("MergedProbes")

def exome__baitIntervals():
  return exome__intervalListFmt().format("Regions")

