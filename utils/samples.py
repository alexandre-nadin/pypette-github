#!/usr/bin/env python
import utils.configs

class SamplesManager(object):
  """
  Manages samples.
  """ 
  def __init__(self, name, namespace):
    self.samples_confman = utils.configs.SamplesConfigManager(
      'samples', 
      self.name, 
      namespace=self.namespace
    ).loadDftConfig() 

class SamplesConfigManager(utils.configs.ConfigManagerTemplate):
  """
  Manages configuration files for samples.
  """
  extensions = ('.csv', '.tsv',)
  def __init__(self, *args, **kwargs):
    super(SamplesConfigManager, self).__init__('samples', *args, **kwargs)
    
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
 
    """ Update pipeline manager's samples """
    self.namespace['pipeline_manager'].samples = data
