import utils.configs, utils.samples, utils.manager
from utils.dicts import toAddict, popFirst
from utils.files import extension as extensionOf
from utils.fastq_helper import FastqFile
from utils.strings import StringFormatter
import addict
import os, sys
import pandas as pd

class SamplesManager(utils.manager.Manager):
  """
  Manages samples.
  """ 
  def __init__(self, prefix, namespace):
    super(SamplesManager, self).__init__()
    self.configManager = utils.samples.SamplesConfigManager(
                            config_prefix = prefix, 
                            namespace     = namespace)
    self.data = None

  def query(self, query, selectedCols=[], toDict=False):
    """
    Queries a pandas DataFrame with the given 'query'.
    Filters the specified 'selectedCols' if any.
    Returns an addict.Dict of all samples if 'toDict', else a pandas.DataFrame by default.
    """
    data = self.data

    """ Query data """
    if query:
      data = data.query(query)
      if data.empty:
        return data

    """ Select Columns """
    if selectedCols:
      data = data[selectedCols]

    """ Format data """
    if toDict:
      data = addict.Dict(data.T.to_dict())

    return data

  @popFirst
  def queryFirst(self, query):
    """
    Returns an addict.Dict of the first sample matching the given pandas DataFrame query string.
    """
    return self.query(query, toDict=True)
 
  def queryNameOrId(self, nameOrId):
    """
    Returns an addict.Dict of all samples matching the given NameOrId.
    """
    try:
      return self.query(
               'sample_id=={noi} or sample_name=={noi}'
                 .format(noi=int(nameOrId)),
               toDict=True)
    except ValueError:
      return self.query(
               'sample_name=="{}"'.format(nameOrId),
               toDict=True)

  @popFirst 
  def queryFirstNameOrId(self, nameOrId):
    """
    Returns an addict.Dict of the first sample matching the given nameOrId.
    """
    return self.queryNameOrId(nameOrId)
  
  def load(self, file=None, once=False, **kwargs):
    if self.data is not None and once:
      pass
    else:
      self.data = self.configManager.load(file, **kwargs)

  def dataSampleSheet(self, file, **kwargs):
    """
    Loads a :file: samplesheet.
    """
    return self.configManager.load(file, **kwargs)
    
  def getFields(self, fields=[]):
    return self.data[fields]

  def addStringFixes(self, s, prefix="", suffix="", **kwargs):
    """
    Adds the given :prefix: and :suffix: to the :s: string
    """
    return f"{prefix}{s}{suffix}"

  def map(self, s, mapSuffix=True, withResult=False, file=None, **kwargs):
    self.load(once=True, file=file, **kwargs)
    if mapSuffix:
      res = self.buildStringFromKeywords(
              self.addStringFixes(s, **kwargs), 
              **kwargs)
    else:
      res = [ 
        self.addStringFixes(bstring, **kwargs)
        for bstring in self.buildStringFromKeywords(s, **kwargs)
      ]
    
    if withResult and not res:
      self.log.error(f"No result found for query '{s}' and keywords {kwargs}.")
      raise 
    else:
      return res

  def buildStringFromKeywords(self, s, unique=True, derefKwargs=[], requiredKeys=[], **kwargs):
    """
    Returns list of string by formatting the given string :s: with selected columns from filtered samples.
    This is done by:
     - Deducing matching sample DataFrame columns based on given string :s: keywords.
     - Building query based on :kwargs: keywords.
     - Querying sample DataFrame and selects matching columns.
    """
    queryFilter = dict(kwargs.items())

    for key in requiredKeys:
      if key not in queryFilter.keys() or not queryFilter[key]:
        return []

    """ Check all """
    for col in self.data.columns:
      if col in kwargs.keys() and kwargs[col] in ['all', 'each']:
        queryFilter.pop(col, None)
        if col in derefKwargs:
          kwargs.pop(col, None) 

    """ Formatted String """
    # Ensures required fastq fields are with their field separator
    fqFieldsWithSep = { key: FastqFile.fieldWithSepCls(key, val)
                            for key, val in kwargs.items()
                      }
    fs = StringFormatter(s).formatPartialMap(keepMissingKeys=True, **fqFieldsWithSep)

    """ Required Columns """
    required_cols = [ col 
      for col in self.data.columns 
      if col in fs.keywords() 
    ]
   
    """ Set Query Dict """
    # Get correct value if field is part of FastqFile fields.
    fqFieldsQuery = {
      key: FastqFile.fieldNoSepCls(key, val)
      for key, val in queryFilter.items()
      if key in self.data.columns 
    }

    if fqFieldsQuery:
      query = " and ".join([ f"{key}=='{val}'" for key, val in fqFieldsQuery.items()])
    else:
      query = ""
    
    """ Query DataFrame """
    samples = self.query(query, selectedCols=required_cols)
    ret = [
      fs.formatPartialMap(
        keepMissingKeys=False,
        **dict(zip(required_cols, values)))
      for values in samples.values
      if not samples.empty
    ]

    if unique:
      ret = list(set(ret))

    return ret
  
  def listsToSamplesheet(self, listLines, delimiter):
    """
    Takes in a list of line lists and formats them to a Samplesheet output.
    """
    return os.linesep.join(
      delimiter.join([elem if elem else "" for elem in line]) 
      for line in listLines)


class SamplesConfigManager(utils.configs.ConfigManagerTemplate):
  """
  Manages configuration files for samples.
  """
  def __init__(self, *args, **kwargs):
    super(SamplesConfigManager, self).__init__('samples', *args, **kwargs)
 
  @property
  def extensionsDelimiters(self):
    """ Associates delimiter to file extensions. """
    return { 
      '.csv': ',', 
      '.tsv': '\t'
    }
 
  @property
  def extensions(self):
    return tuple(self.extensionsDelimiters.keys())
  
  @property
  def configfileBase(self):
    return "samples/samples"
 
  def load(self, file=None, indexlowcase_cols=True, **kwargs):
    """
    Loads a samples file into a pandas dataframe.
    If specified, lowercases the column names. 
    """
    file = self.configFileDefault if file is None else file.format(**kwargs)
    if not os.path.exists(file):
      sys.exit(f"Sample file '{file}' does not exist.")
    data = pd.read_csv(
      file, 
      delimiter= self.extensionsDelimiters[extensionOf(file).strip()],
      dtype=str)
    if indexlowcase_cols:
      data.columns = map(str.lower, data.columns)

    """ Replace NaN with None """
    data = data.astype(object).where(pd.notnull(data), None)
    return data
