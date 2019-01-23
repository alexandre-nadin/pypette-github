import utils.configs, utils.samples, utils.manager
from utils.dicts import toAddict, popFirst
from utils.files import extension as extensionOf
import addict

class SamplesManager(utils.manager.Manager):
  """
  Manages samples.
  """ 
  def __init__(self, prefix, namespace):
    super(SamplesManager, self).__init__()
    self.config_manager = utils.samples.SamplesConfigManager(
                            config_prefix = prefix, 
                            namespace     = namespace)
    self.data = self.config_manager.loadDftConfig() 

  def query(self, query, selectedCols=[], toDict=False):
    """
    Queries a pandas DataFrame with the given 'query'.
    Filters the specified 'selectedCols' if any.
    Returns an addict.Dict of all samples if 'toDict', else a pandas.DataFrame by default.
    """
    samples = self.data.query(query)
    if samples.empty:
      self.log.error(
        "No information found for sample filter '{}'."
         .format(query)
      )
      raise
    else:
      pass

    """ Select Columns """
    if selectedCols:
      samples = samples[selectedCols]

    """ Return format """
    if toDict:
      ret = addict.Dict(samples.T.to_dict())
    else:
      ret = samples

    return ret

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

  def getFields(self, fields=[]):
    return self.data[fields]
  
  @popFirst 
  def queryFirstNameOrId(self, nameOrId):
    """
    Returns an addict.Dict of the first sample matching the given nameOrId.
    """
    return self.queryNameOrId(nameOrId)
  
  def load(self, *args, **kwargs):
    self.data = self.config_manager.loadConfig(*args, **kwargs)


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
    return "samples"
 
  def loadConfig(self, file, indexlowcase_cols=True):
    """
    Loads a samples file into a pandas dataframe.
    If specified, lowercases the column names. 
    """
    import pandas as pd
    data = pd.read_csv(
      file, 
      delimiter= self.extensionsDelimiters[extensionOf(file).strip()])
    if indexlowcase_cols:
      data.columns = map(str.lower, data.columns)

    """ Replace NaN with None """
    data = data.astype(object).where(pd.notnull(data), None)
    return data 
