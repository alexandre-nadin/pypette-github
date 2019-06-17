import os
import utils.configs, utils.samples
from utils.manager import Manager
from utils import environ
from utils.files import extensionless

class PipelineManager(Manager):
  """ """
  # Expected tag for application's environment variables
  VARENV_TAG = "_CPIPE_"
  VARENV_NAMES = ( 
    'home', 'project', 'pipeName', 'pipeSnake', 
    'execDir', 'workflowDir', 'clusterMntPoint', 'shellEnv',
  )

  def __init__(self, namespace, name="Default", sampleBased=True):
    super(PipelineManager, self).__init__()
    environ.setTaggedVarEnvsAttrs(self, tag=self.__class__.VARENV_TAG)
    self.checkVarenvAttrs()
    self.namespace     = namespace
    self.modulesDir    = os.path.join(self.home, "modules")
    self.pipelinesDir  = os.path.join(self.home, "pipelines")
    self.params        = []
    self.cleanables    = []
    self.sampleManager = utils.samples.SamplesManager(self.pipeName, self.namespace)
    self.configManager = PipelineConfigManager(
                              config_prefix = self.pipeName, 
                              namespace     = self.namespace)
    self.sampleBased   = sampleBased
    self.moduleDir     = ""
    self.updateNamespace()
 
    self.sampleBased   = True
    self.deepStructure = True

    """ Required Config Files """
    self.configFiles    = ()

    """ Load internal default config """
    self._loadConfigFiles()

    """ Set default working dir """
    self.setDefaultWorkingDir()

  def checkVarenvAttrs(self):
    for varenv in self.__class__.VARENV_NAMES:
      self.checkVarenvAttr(varenv)

  def checkVarenvAttr(self, attr):
      assert hasattr(self, attr), f"Environment variable '{attr}' not found."

  @property
  def workflow(self):
    return self.namespace['workflow']

  @property 
  def snakefile(self):
    """
    Returns the path to the given pipeline's snakefile.
    """
    return os.path.join(
      self.home, "pipelines", self.name, f"{self.name}.sk"
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
    return self.sampleManager
  
  @property
  def sampleExtensions(self):
    return self.sampleManager.configManager.extensionsDelimiters

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
    Retrieves the value of an addict from string.
    The addict's instance name is expected:
     - to be the first element split from the string.
     - to be in the globals.
    """
    keys = string.split('.')
    return self.configFromKeys(self.namespace[keys[0]], keys[1:])
    
  def configFromKeys(self, config, keys=[]):
    """
    Retrieves recursively the value of an addict from a list of keys.
    """
    if not keys:
      return config
    elif len(keys) > 1:
      return self.configFromKeys(config[keys[0]], keys[1:])
    else:
      return config[keys[0]]

  def missingConfigFiles(self):
    """
    Returns the required files that are missing.
    """
    return [ conf
             for conf in self.configFiles
             if not os.path.exists(conf)
             and not os.path.isfile(conf)
           ]

  def addConfigFiles(self, *args):
    self.configFiles = tuple(set( (*self.configFiles, *args) ))
  
  def loadConfigFiles(self):
    """ Check missing files """
    missingFiles = self.missingConfigFiles()
    if missingFiles:
      self.log.warning(f"Missing required files '{missingFiles}'")

    """ Load non missing config """
    for conf in self.configFiles:
      if conf not in missingFiles:
        self.configManager.load(conf)
 
  def _loadConfigFiles(self):
    """ 
    Loads the pipeline's internal config files
    """
    for conf in self._configFiles():
      self.configManager.load(conf)

  def _configFiles(self):
    """
    Returns the given pipeline's internal config files.
    """
    import glob
    ret = [] 
    for ext in self.configManager.extensions:
      ret.extend(
        glob.glob(f"{self.pipelinesDir}/{self.pipeName}/*{ext}"))
    return ret

  @property
  def pipelines(self):
    return [
      path 
      for path in next(os.walk(self.pipelinesDir))[1]
      if not path.startswith('.')
    ]

  def defaultWorkingDir(self):
    return os.path.join(
      self.workflowDir, 
      self.config.pipeline.outDir,
      self.project)

  def setDefaultWorkingDir(self):
    if not self.hasCustomDir():
      outDir = self.defaultWorkingDir()
      os.makedirs(outDir, exist_ok=True)
      os.chdir(outDir)
    self.log.info(f"Working dir set to '{os.getcwd()}'")

  def hasCustomDir(self):
    return self.workflow.workdir_init != self.execDir
  
  # ------------ 
  # Snakefiles
  # ------------    
  def include(self, name, outDir=True, asWorkflow=""):
    """
    Includes the given file allowing to reflect the workflow of processes in the ouput dir.
    By default, sets the pipeline manager workflowDir to the module's basename if :outDir:.
    Concatenates the module's basename to workflowDir if :asWorkflow: is set (default).
    Example:
      :name: module3/module3.sk
      workflowDir = "module1/module2"
      Sets workflowDir to "module1/module2/module3" with :outDir: True and :asWorkflow: True
      Sets workflowDir to "module3" with :outDir: True and :asWorkflow: False.
      Doesn't touch workflowDir if :outDir: False
    """

    """ Set workflowDir"""
    if outDir:
      basename = extensionless(os.path.basename(name))
      if asWorkflow:
        self.workflowDir = os.path.join(self.workflowDir, asWorkflow)
      self.moduleDir = basename

    """ Include File """ 
    self.workflow.include(name)

  def includePipeline(self, name):
    self.include(os.path.join(self.pipelinesDir, name))

  def includeModule(self, name, *args, **kwargs):
    self.include(os.path.join(self.modulesDir, name), **kwargs)

  def includeModules(self, *modules, withConfigFiles=False, **kwargs):
    """ Check required files """
    missingFiles = self.missingConfigFiles() 
    if missingFiles and withConfigFiles:
      self.log.warning(f"Couldn't include modules '{modules}': They depend on the missing files '{missingFiles}'.")
    else:
      for module in modules:
        self.includeModule(module, **kwargs)

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
        self.log.warning(f"Parameter '{param}' not found in configuration.")
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

  @property
  def extensions(self):
    return ('.yaml', '.json',)

  @property
  def configfileBase(self):
    return "config"

  def load(self, file):
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
