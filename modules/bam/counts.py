import pandas as pd
import os
import glob
from functools import reduce

def counts__mergedGenesDataFrameFromCounts(files):
  """ Merged all samples' gene counts dataframe """
  return counts__fmtColnames(
           reduce(
             pd.merge, 
             counts__genesDataFrames(files)))

def counts__genesDataFrames(files, compression='gzip'):
  """ Creates all samples' gene counts dataframes """
  return [ 
    pd.read_csv(f, delimiter='\t', skiprows=1, compression=compression)
      .iloc[:, [0, -1]]
    for f in files
  ]

def counts__genesDataFrame(df):
  """ Actually selects the first and last columns of the given dataframe """
  assert(len(df.columns) > 2)
  return df.copy().iloc[:, [0, -1]]

def counts__fmtColnames(df):
  """ Formats the given dataframe's column names. """
  new = df.copy()
  new.columns = [ 
    colname.rstrip('.bam') 
    for colname in df.columns.map(os.path.basename) ]   
  return new
