def mapping__setAligner(name):
  workflow.globals[mapping__alignerVarName()] = name

def mapping__alignerDft():
  return 'aligner'

def mapping__alignerVarName():
  return '_mapping__aligner'

def mapping__getAligner():
  if not mapping__alignerVarName() in workflow.globals.keys():
    mapping__setAligner(mapping__alignerDft())
  return workflow.globals[mapping__alignerVarName()]
