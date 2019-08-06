import pandas as pd

def dge__deseq2ParamsDft(metadataFile):
  """ Get default parameters """
  data = pd.read_csv(metadataFile, delimiter='\t')
  factors = [ 
    column
    for column in data.columns
    if 'sample' not in column.lower()
  ]
  
  refFactor = factors[0]
  refLevel  = data[refFactor][0]
  string    = f"~{refFactor}"

  """ Substitute default params if not defined """
  dge = pipeman.config.pipeline.modules.dge
  if not dge.design.factors:
    pipeman.log.info(f"Default DGE design factors: {factors}")
    dge.design.factors = factors
  if not dge.design.refFactor:
    pipeman.log.info(f"Default DGE design refFactor: {refFactor}")
    dge.design.refFactor = refFactor
  if not dge.design.refLevel:
    pipeman.log.info(f"Default DGE design refLevel: {refLevel}")
    dge.design.refLevel = refLevel
  if not dge.design.string:
    pipeman.log.info(f"Default DGE design string: {string}")
    dge.design.string = string 

  return dge  

