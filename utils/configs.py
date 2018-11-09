#!/usr/bin/env python
import sys
import os
from dataclasses import dataclass
from easydev import Logging
import utils.files
from utils.manager import Manager

@dataclass
class ConfigManagerTemplate(Manager):
  """ Params """
  config_type    : str
  config_prefix  : str  = ""
  namespace      : dict = None

  extensions = ()
  """ Attributes """
  def __post_init__(self):
    super(ConfigManagerTemplate, self).__init__()

  def loadDftConfig(self):
    """
    Loads the default pipeline configuration file if it exists.
    """
    config = self.configFileDefault
    if config:
      return self.loadConfig(config)
    else:
      return None

  def loadConfig(self, file):
    """
    Override in relevant subclass to correctly load data from the given file.
    """
    raise Exception(
      "Function {} has to be overridden in a subclass."
       .format(sys._getframe().f_code.co_name))

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
          "{}-".format(self.config_prefix.lower() if self.config_prefix else ""),
          self.config_type.lower()
        )
    )

class PipelineConfigManager(ConfigManagerTemplate):
  extensions = ('.yaml', '.json',)
  def __init__(self, *args, **kwargs):
    super(PipelineConfigManager, self).__init__('config', *args, **kwargs)
    self.loadDftConfig()

  def loadConfig(self, file):
    """
    loads the given snakemake configuration file.
    Updates and converts it to an Addict.
    """
    self.namespace['workflow'].configfile(file)
    self.updateNamespace()

  def updateNamespace(self):
    """
    Converts the config from a regular Python dictionnary into an addict's.
    """
    import addict
    self.namespace['config'] = addict.Dict(self.namespace['config'])
