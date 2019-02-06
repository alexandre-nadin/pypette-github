import os
import utils.configs, utils.samples
from utils.manager import Manager
from utils import environ
from utils.files import extensionless

class PipelineManager(Manager):
  """ """
  # Expected tag for application's environment variables
  VARENV_TAG = "_CPIPE_"
  VARENV_NAMES = [ 'home', 'project', 'pipe_name', 'pipe_snake', 'cluster_mnt_point' ]

  def __init__(self, namespace, name="Default", sampleBased=True):
    super(PipelineManager, self).__init__()
    environ.setTaggedVarEnvsAttrs(self, tag=self.__class__.VARENV_TAG, stripTag=True)
    self.checkVarenvAttrs()
    self.namespace        = namespace
    self.dir_modules      = os.path.join(self.home, "modules")
    self.dir_pipelines    = os.path.join(self.home, "pipelines")
    self.params           = []
    self.cleanables       = []
    self.samples_manager  = utils.samples.SamplesManager(self.pipe_name, self.namespace)
    self.config_manager   = PipelineConfigManager(
                              config_prefix = self.pipe_name, 
                              namespace     = self.namespace)
    self.sample_based = sampleBased
    self.workflow_dir = "{sample_name}" if self.sample_based else ""
    self.module_dir   = ""
    self.updateNamespace()
 
    self.sample_based     = True
    self.deep_structure   = True

  def checkVarenvAttrs(self):
    for varenv in self.__class__.VARENV_NAMES:
      self.checkVarenvAttr(varenv)

  def checkVarenvAttr(self, attr):
    assert hasattr(self, attr)

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

  def updateNamespace(self):
    """
    Saves itself in the global namespace
    """
    self.namespace['pipeline_manager'] = self

  # ---------
  # Samples
  # ---------
  @property
  def samples(self):
    return self.samples_manager
  
  @property
  def sampleExtensions(self):
    return self.samples_manager.config_manager.extensionsDelimiters

  # -----------------
  # Pipeline Config
  # -----------------
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
  def include(self, name, outDir=True, asWorkflow=""):
    """
    Includes the given file allowing to reflect the workflow of processes in the ouput dir.
    By default, sets the pipeline manager workflow_dir to the module's basename if :outDir:.
    Concatenates the module's basename to workflow_dir if :asWorkflow: is set (default).
    Example:
      :name: module3/module3.sk
      workflow_dir = "module1/module2"
      Sets workflow_dir to "module1/module2/module3" with :outDir: True and :asWorkflow: True
      Sets workflow_dir to "module3" with :outDir: True and :asWorkflow: False.
      Doesn't touch workflow_dir if :outDir: False
    """

    """ Set workflow_dir"""
    if outDir:
      basename = extensionless(os.path.basename(name))
      if asWorkflow:
        self.workflow_dir = os.path.join(self.workflow_dir, asWorkflow)
      self.module_dir = basename

    """ Include File """ 
    self.workflow.include(name)

  def includeModule(self, name, *args, **kwargs):
    self.include(os.path.join(self.dir_modules, name), **kwargs)

  def includePipeline(self, name):
    self.include(os.path.join(self.dir_pipelines, name))
  
  def _loadModule(self, name):
    pass
 
  def addModule(self, name):
    pass

  # -----------------------
  # Wildcards Constraints
  # -----------------------
  def updateWildcardConstraints(self, **wildcards):
    self.workflow.global_wildcard_constraints(**wildcards);

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

class PipelineConfigManager(utils.configs.ConfigManagerTemplate):
  def __init__(self, *args, **kwargs):
    super(PipelineConfigManager, self).__init__('config', *args, **kwargs)
    self.loadDftConfig()

  @property
  def extensions(self):
    return ('.yaml', '.json',)

  @property
  def configfileBase(self):
    return "config"

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
