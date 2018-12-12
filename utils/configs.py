#!/usr/bin/env python
import sys
import os
from dataclasses import dataclass
from easydev import Logging
import utils.files
from utils.manager import Manager
from utils.classes import overrideProperty

@dataclass
class ConfigManagerTemplate(Manager):
  """ Params """
  config_type    : str
  config_prefix  : str  = ""
  namespace      : dict = None

  """ Attributes """
  def __post_init__(self):
    super(ConfigManagerTemplate, self).__init__()

  @property
  @overrideProperty
  def extensions(self): 
    return "Returns a tuple of possible extensions."

  @overrideProperty
  def configFileDefault(self):
    return "Returns the default configuration file name."

  @overrideProperty
  def loadConfig(self, file):
    return "Correctly loads data from the given file."

  @property
  @overrideProperty
  def configfileBase(self):
    return "Returns the base name of configuration files, without extensions."

  def loadDftConfig(self):
    """
    Loads the default pipeline configuration file if it exists.
    """
    config = self.configFileDefault
    if config:
      return self.loadConfig(config)
    else:
      return None

  @property
  def configFileDefault(self):
    """
    Gives the default config file found among all possible.
    """
    configs = [ config
      for config in self.configfiles()
      if os.path.isfile(config)
    ]

    if configs:
      config = configs[0]
      self.log.info(
        "{} files found: {}. Default taken: '{}'."
          .format(
            self.config_type.capitalize(), 
            configs, 
            config)
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
    return [ conf
      for conf in self.configfilesExpected()
      if os.path.exists(conf)
    ]

  def configfilesExpected(self):
    """
    Returns expected default configuration files for each possible extension.
    """
    return [ "{}{}"
      .format(self.configfileBase, ext)
      for ext in self.extensions
    ]

