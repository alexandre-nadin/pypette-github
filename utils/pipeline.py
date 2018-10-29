#!/usr/bin/env python
import os
from utils import files
from easydev import Logging

class PipelineManager():
  """ """
  home          = os.environ['CTGB_PIPE_HOME']
  dir_modules   = os.path.join(home, "modules")
  dir_pipelines = os.path.join(home, "pipelines")

  def __init__(self, name, namespace):
    self.name       = name
    self.namespace  = namespace
    self.params     = []
    self.log        = Logging(name, "WARNING")
    self.autoconfig()
      
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
 
  # ---------
  # Configs
  # --------- 
  def autoconfig(self):
    """
    Loads default config file if it exists or warns.
    """
    if os.path.exists(self.configfile):
      self.loadConfig(self.configfile)
    else:
      self.log.warning("Default configuration file '{}' not found.".format(self.configfile))

  @property
  def config(self):
    """
    Returns Snakemake's global config variable
    """
    return self.namespace['config']

  @property 
  def configfile(self):
    return "{}-config.yaml".format(files.extensionless(self.name))

  def loadConfig(self, file):
    """
    Loads a config file. Updates config dict from namespace.
    Updates and converts it to an Adddict.
    """
    self.workflow.configfile(file)
    self.updateConfig()

  def updateConfig(self):
    """
    Converts the config from a regular Python dictionnary into an addict's.
    """
    import addict
    self.namespace['config'] = addict.Dict(self.config)

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

class Pipeline():
  def __init__(self, path):
    self.path = path
    self.snakefile = None
