#!/usr/bin/env python
import os
from utils import files
from easydev import Logging

class PipelineManager(object):
  """ """
  home          = os.environ['CTGB_PIPE_HOME']
  dir_modules   = os.path.join(home, "modules")
  dir_pipelines = os.path.join(home, "pipelines")

  def __init__(self, name, namespace):
    self.name       = name
    self.namespace  = namespace
    self.params     = []
    self.cleanables = []
    self.log        = Logging("pipe:{}".format(name), "INFO")
    self.samples    = None
    self.pipeline_confman = PipelineConfigManager(
      'config', 
      self.name,
      namespace=self.namespace
    ).loadDftConfig()
    self.samples_confman = SamplesConfigManager(
      'samples', 
      self.name, 
      namespace=self.namespace
    ).loadDftConfig() 
 
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

    """
    """

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

  # ---------------
  # Cleaning files
  # ---------------
  def toClean(self, *patterns):
    """
    Adds the given patterns to the list of files to clean.
    """
    self.cleanables.extend([*patterns])

from dataclasses import dataclass

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
          .format(self.config_type.capitalize(), self.configfiles_expected(), config)
      )
      return config
    else:
      self.log.warning(
        "No default {} file found among {}."
          .format(self.config_type, self.configfiles_expected())
      )
      return None

  def configfiles(self):
    """
    Builds potential configuration file names.
    Returns only those which do exist.
    """
    return [
      conf for conf in self.configfiles_expected()
        if os.path.exists(conf)
    ]

  def configfiles_expected(self):
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
    filetype = files.extension(file).lstrip('.')
    fread = getattr(pd, 'read_{}'.format(filetype))
    data = fread(file)
    if indexlowcase_cols:
      data.columns = map(str.lower, data.columns)

    """ Replace NaN with None """
    data = data.astype(object).where(pd.notnull(data), None)
 
    """ Update pipeline manager's samples """
    self.namespace['pipeline_manager'].samples = data

class Pipeline():
  def __init__(self, path):
    self.path = path
    self.snakefile = None

# ------
# Shell
# ------
def lshell(command, allow_empty_lines=False):
  """
  Returns the output of a given shell command in an array.
  Each element is an output line.
  Filters empty strings by default.
  """
  out = subprocess.check_output(command, shell=True).decode().split(os.linesep)
  return out if allow_empty_lines else [ _elem for _elem in out if _elem ] 
