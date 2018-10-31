#!/usr/bin/env python
import os
from utils import files
from easydev import Logging

class PipelineManager(object):
  """ """
  home          = os.environ['CTGB_PIPE_HOME']
  dir_modules   = os.path.join(home, "modules")
  dir_pipelines = os.path.join(home, "pipelines")
  config_exts   = ('.yaml', '.json')
  sample_exts   = ('.csv', '.tsv')

  def __init__(self, name, namespace):
    self.name       = name
    self.namespace  = namespace
    self.params     = []
    self.log        = Logging("pipe:{}".format(name), "INFO")
    self.samples    = None
    self.autoconfig()
    self.autosamples()
      
  @property
  def workflow(self):
    return self.namespace['workflow']

  @property 
  def snakefile(self):
    """
    Returns the path to the given pipeline's snakefile.
    """
    return os.path.join(
      self.home, "pipelines", self.name, "{}.sk".format(self.name)
    )

  # --------
  # Samples
  # --------

  # ---------
  # Configs
  # --------- 
  def autoconfig(self):
    """
    Loads default config file if it exists.
    """
    configs = self.configfiles()
    if configs:
      config = configs.pop(0)
      self.log.info(
        "Default configuration file: {}. Found among {}"
          .format(config, self.configfiles_expected())
      )
      self.loadConfig(config)
    else:
      self.log.warning(
        "No default configuration file found among {}."
          .format(self.configfiles_expected())
      )

  def autosamples(self):
    """
    Loads default samples file if it exists.
    """
    configs = self.samplefiles()
    if configs:
      config = configs.pop(0)
      self.log.info(
        "Default samples file: {}. Found among {}"
          .format(config, self.samplefiles_expected())
      )
      self.loadSamples(config)
    else:
      self.log.warning(
        "Default samples file not found among {}."
          .format(self.samplefiles_expected())
      )
  
  def configfiles(self):
    """
    Builds potential configuration file names.
    Returns only those who do exist.
    """
    return [
      conf for conf in self.configfiles_expected()
        if os.path.exists(conf)
    ]

  def samplefiles(self):
    """
    Builds potential samples file names.
    Returns only those who do exist.
    """
    return [
      conf for conf in self.samplefiles_expected()
        if os.path.exists(conf)
    ]

  def configfiles_expected(self):
    return [ 
      "{}{}".format(self.configfileBase, ext)
        for ext in self.config_exts
    ]

  def samplefiles_expected(self):
    return [ 
      "{}{}".format(self.samplefileBase, ext)
        for ext in self.sample_exts
    ]


  @property
  def configfileBase(self):
    """
    Returns the base name of configuration files, without extensions.
    """
    return "{}-config".format(files.extensionless(self.name))

  @property
  def samplefileBase(self):
    """
    Returns the base name of sample files, without extensions.
    """
    return "{}-samples".format(files.extensionless(self.name))

  def loadConfig(self, file):
    """
    Loads a config file. Updates config dict from namespace.
    Updates and converts it to an Adddict.
    """
    self.workflow.configfile(file)
    self.updateConfig()

  def loadSamples(self, file, indexlowcase_cols=True):
    """
    Loads a samples file into a pandas dataframe.
    If specified, lowercases the column names. 
    """
    import pandas as pd
    filetype = files.extension(file).lstrip('.')
    fread = getattr(pd, 'read_{}'.format(filetype))
    data = fread(file)
    if indexlowcase_cols:
      data.columns = map(str.lower, data.columns)
    self.samples = data

  @property
  def config(self):
    """
    Returns Snakemake's global config variable
    """
    return self.namespace['config']

  def configFromKeysString(self, string=""):
    """
    Retreives the value of an addict from string.
    The addict's instance name is expected:
     - to be the first element split from the string.
     - to be in the globals.
    """
    keys = string.split('.')
    return self.configFromKeys(self.namespace[keys[0]], keys[1:])
    
  def configFromKeys(self, config, keys=[]):
    """
    Retreives recursively the value of an addict from a list of keys.
    """
    if not keys:
      return config
    elif len(keys) > 1:
      return self.configFromKeys(config[keys[0]], keys[1:])
    else:
      return config[keys[0]]

  def updateConfig(self):
    """
    Converts the config from a regular Python dictionnary into an addict's.
    """
    import addict
    self.namespace['config'] = addict.Dict(self.config)

  # ---------
  # Samples
  # ---------
  @property 
  def samplefile(self):
    return "{}-samples.tsv".format(files.extensionless(self.name))

  # ------------ 
  # Snakefiles
  # ------------    
  def include(self, name):
    self.workflow.include(name)

  def includeModule(self, name):
    self.include(os.path.join(self.dir_modules, name))

  def includePipeline(self, name):
    self.include(os.path.join(self.dir_pipelines, name))
  
  def _loadModule(self, name):
    pass
 
  def addModule(self, name):
    pass

  # ------------
  # Parameters
  # ------------
  def setParams(self, *params):
    """
    
    """
    all_set = True
    for param in params:
      if not self.configFromKeysString(param):
        self.log.warning("Parameter '{}' not found in configuration.".format(param))
        all_set = False
    if not all_set:
      raise

  def addParams(self, *params):
    """
    Adds the given parameters to a list.
    Each parameter is unique.
    """
    for param in params:
      self.addParam(param)
    self.params = list(set(self.params))
     
  def addParam(self, param):
    self.params.extend([param,])
 
  def areParamsOk(self):
    try:
      self.checkParams()
      return True
    except:
      return False
 
  def checkParams(self):
    toraise = False
    for param in self.params:
      if not self.configFromKeysString(param):
        #self.log.warning("Parameter '{}' not set in configuration.".format(param))
        toraise = True
    if toraise:
      raise

class Pipeline():
  def __init__(self, path):
    self.path = path
    self.snakefile = None
