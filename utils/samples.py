#!/usr/bin/env python
import utils.configs, utils.samples, utils.manager
from utils.dicts import toAddict, popFirst

class SamplesManager(utils.manager.Manager):
  """
  Manages samples.
  """ 
  def __init__(self, prefix, namespace):
    super(SamplesManager, self).__init__()
    self.config_manager = utils.samples.SamplesConfigManager(
      config_prefix=prefix, namespace=namespace)
    self.data = self.config_manager.loadDftConfig() 

  @toAddict
  def query(self, query):
    """
    Returns an addict.Dict of all samples matching the given pandas DataFrame's query string.
    """
    samples = self.data.query(query)
    if samples.empty:
      self.log.error(
        "No information found for sample filter '{}'."
         .format(query)
      )
      raise
    else:
      return samples.T.to_dict()

  @popFirst
  def queryFirst(self, query):
    """
    Returns an addict.Dict of the first sample matching the fiven pandas DataFrame query string.
    """
    return self.query(query)
 
  def queryNameOrId(self, nameOrId):
    """
    Returns an addict.Dict of all samples matching the given NameOrId.
    """
    try:
      return self.query('sample_id=={nb} or sample_name=={nb}'
        .format(nb=int(nameOrId)))
    except ValueError:
      return self.query('sample_name=="{}"'.format(nameOrId))
  
  @popFirst 
  def queryFirstNameOrId(self, nameOrId):
    """
    Returns an addict.Dict of the first sample matching the given nameOrId.
    """
    return self.queryNameOrId(nameOrId)

class SamplesConfigManager(utils.configs.ConfigManagerTemplate):
  """
  Manages configuration files for samples.
  """
  def __init__(self, *args, **kwargs):
    super(SamplesConfigManager, self).__init__('samples', *args, **kwargs)
   
  @property
  def extensions(self):
    return ('.csv', '.tsv',)
  
  @property
  def configfileBase(self):
    return "samples"
 
  def loadConfig(self, file, indexlowcase_cols=True):
    """
    Loads a samples file into a pandas dataframe.
    If specified, lowercases the column names. 
    """
    import pandas as pd
    filetype = utils.files.extension(file).lstrip('.')
    fread = getattr(pd, 'read_{}'.format(filetype))
    data = fread(file)
    if indexlowcase_cols:
      data.columns = map(str.lower, data.columns)

    """ Replace NaN with None """
    data = data.astype(object).where(pd.notnull(data), None)
   
    return data 
