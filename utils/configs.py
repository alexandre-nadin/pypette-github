#!/usr/bin/env python
import sys
import os
from dataclasses import dataclass
from easydev import Logging
import utils.files

@dataclass
class ConfigManagerTemplate(object):
  """ Params """
  config_type    : str
  config_prefix  : str  = ""
  namespace      : dict = None

  extensions = ()
  """ Attributes """
  def __post_init__(self):
    self.log = Logging("pipe:{}".format(self.config_type), "INFO")

  def loadDftConfig(self):
    """
    Loads the default pipeline configuration file if it exists.
    """
    config = self.configFileDefault
    if config:
      self.loadConfig(config)
    return self

  def loadConfig(self, file):
    raise Exception(
      "Function {} has to be overridden in a subclass."
       .format(sys._getframe().f_code.co_name))

  def updateNamespaceConfig(self):
    """
    Converts the config from a regular Python dictionnary into an addict's.
    """
    import addict
    self.namespace['config'] = addict.Dict(self.namespace['config'])

  @property
  def configFileDefault(self):
    """
    Gives the default config file found among all possible.
    """
    configs = self.configfiles()
    if configs:
      config = configs.pop(0)
      self.log.info(
        "{} files found: {}. Default taken: '{}'."
          .format(self.config_type.capitalize(), self.configfilesExpected(), config)
      )
      return config
    else:
      self.log.warning(
        "No default {} file found among {}."
          .format(self.config_type, self.configfilesExpected())
      )
      return None

  def configfiles(self):
    """
    Builds potential configuration file names.
    Returns only those which do exist.
    """
    return [
      conf for conf in self.configfilesExpected()
        if os.path.exists(conf)
    ]

  def configfilesExpected(self):
    """
    Returns expected default configuration files for each possible extension.
    """
    return [ 
      "{}{}".format(self.configfileBase, ext)
        for ext in self.extensions
    ]

  @property
  def configfileBase(self):
    """
    Returns the base name of configuration files, without extensions.
    """
    return (
      "{}{}"
        .format(
          "{}-".format(self.config_prefix if self.config_prefix else ""),
          self.config_type
        )
    )

    return (
      "{}{}".format(
        "{}-".format(self.config_prefix if self.config_prefix else ""),
        self.config_type
      )
    )

class PipelineConfigManager(ConfigManagerTemplate):
  extensions = ('.yaml', '.json',)
  def loadConfig(self, file):
    """
    Loads the given snakemake configuration file.
    Updates and converts it to an Addict.
    """
    self.namespace['workflow'].configfile(file)
    self.updateNamespaceConfig()
    
  
class SamplesConfigManager(ConfigManagerTemplate):
  extensions = ('.csv', '.tsv',)
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

