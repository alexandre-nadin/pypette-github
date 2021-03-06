import os
import utils.configs, utils.samples
from utils.manager import Manager
from utils import environ
from utils import regex_helper as rh
from utils.files import extensionless
from snakemake.io import temp
import datetime
from collections import OrderedDict
from utils.strings import StringFormatter

class PipelineManager(Manager):
  """ """
  # Expected tag for application's environment variables
  VARENV_TAG = "_PYPETTE_"
  VARENV_NAMES = ( 
    'home', 'project', 'pipeName', 'pipeSnake', 'exeTime',
    'exeDir', 'workdir', 'clusterMntPoint', 'keepFilesRegex',
  )

  TEMP_FILES = 'kept-temp-files.txt'

  def __init__(self, namespace, name="Default"):
    super(PipelineManager, self).__init__()
    environ.setTaggedVarEnvsAttrs(self, tag=self.__class__.VARENV_TAG)
    self.checkVarenvAttrs()
    self.namespace     = namespace
    self.modulesDir    = os.path.join(self.home, "modules")
    self.pipelinesDir  = os.path.join(self.home, "pipelines")
    self.params        = []
    self.cleanables    = []
    self.targets       = OrderedDict({})
    self.snakefiles    = []
    self.sampleManager = utils.samples.SamplesManager(self.pipeName, self.namespace)
    self.configManager = PipelineConfigManager(
                              config_prefix = self.pipeName, 
                              namespace     = self.namespace)
    self.moduleDir     = ""
    self.updateNamespace()

    """ Required Config Files """
    self.configFiles    = ()

    """ Load internal default config """
    self._loadConfigFiles()

    """ Set default working dir """
    self.setDefaultWorkingDir()

    """ Set default jobs dir """
    self.checkJobsDir()

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

  def input(self, *args, **kwargs):
    """ 
    Allows more clarity to Snakemake input definitions 
    """
    return lambda wildcards: self.samples.map(*args, file="samples/all/runs/{sample_run}/samples.csv", **wildcards, **kwargs)
  
  # ----------------
  # Temporary files
  # ---------------- 
  def temp(self, name):
    if self.isFileToKeep(name):
      self.updateTempFiles(name)
      return name
    else:
      return temp(name)
    

  def isFileToKeep(self, name):
    try:
      if self.keepFilesRegex                              \
      and rh.isRegexInList(self.keepFilesRegex, [name,]):
        return True
      else:
        return False
    except:
      self.log.error(f"That regexp won't do: '{self.keepFilesRegex}'")

  def updateTempFiles(self, name):
    self.touchTempFilesFile()
    with open(self.tempFilesFile(), 'r+') as tempFiles:
      for tempFile in tempFiles:
        if name in tempFile:
          break
      else:
        tempFiles.write(f"{name}\n")

  def touchTempFilesFile(self):
    open(self.tempFilesFile(), 'a').close()
      
  def tempFilesFile(self):
    f = self.config.pipeline.tempFiles
    if not f:
      f = self.TEMP_FILES
    return f

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
      self.config.cluster.stdAnalysisDir,
      self.config.pipeline.outDir,
      self.project)

  def setDefaultWorkingDir(self):
    if not self.hasCustomDir():
      if not self.workdir:
        self.workdir = self.defaultWorkingDir()
      os.makedirs(self.workdir, exist_ok=True)
      os.chdir(self.workdir)
    self.log.info(f"Working directory set to '{os.getcwd()}'")

  def hasCustomDir(self):
    return self.workflow.workdir_init != self.exeDir
 
  # ------------------
  # Snakemake Scripts
  # ------------------ 
  def rscript(self, name):
    """
    Sources an R script, dealing with snakemake parameters.
    """
    # Set R Variables
    if "R_LIBS" not in os.environ:
      os.environ["R_LIBS"] = ""
    os.environ["R_LIBS"] = os.pathsep.join([
      os.environ["R_LIBS"], 
      self.modulesDir]
    ).strip(os.pathsep)

    # Set Pipeline Variables for R scripts
    os.environ["_PYPETTE_SCRIPT"] = os.path.join(self.modulesDir, name)
    os.environ["_PYPETTE_MODULES"] = self.modulesDir
    
    return os.path.join(self.modulesDir, "core/script.R")

   
  # ------------ 
  # Snakefiles
  # ------------    
  def include(self, name, outDir=True, asWorkflow=""):
    """
    Includes the given file allowing to reflect the workflow of processes in the ouput dir.
    By default, sets the pipeline manager workdir to the module's basename if :outDir:.
    Concatenates the module's basename to workdir if :asWorkflow: is set (default).
    Example:
      :name: module3/module3.sk
      workdir = "module1/module2"
      Sets workdir to "module1/module2/module3" with :outDir: True and :asWorkflow: True
      Sets workdir to "module3" with :outDir: True and :asWorkflow: False.
      Doesn't touch workdir if :outDir: False
    """

    """ Set workdir"""
    if outDir:
      basename = extensionless(os.path.basename(name))
      if asWorkflow:
        self.workdir = os.path.join(self.workdir, asWorkflow)
      self.moduleDir = basename

    """ Include File """ 
    self.workflow.include(name)

  def includePipeline(self, name):
    self.include(os.path.join(self.pipelinesDir, name))

  def includeModule(self, name, *args, **kwargs):
    self.include(self.modulePath(name), **kwargs)

  def includeModules(self, *modules, withConfigFiles=False, **kwargs):
    """ Check required files """
    missingFiles = self.missingConfigFiles() 
    if missingFiles and withConfigFiles:
      self.log.warning(f"Couldn't include modules '{modules}': They depend on the missing files '{missingFiles}'.")
    else:
      for module in modules:
        self.includeModule(module, **kwargs)

  def modulePath(self, name):
    """ Returns the module path in pypette directories """
    return os.path.join(self.modulesDir, name)

  def isModule(self, name):
    """ Checks if given {name} is in pypette modules """
    return os.path.isfile(self.modulePath(name))

  def _loadModule(self, name):
    pass
 
  def addModule(self, name):
    pass

  # -------------------------
  # Include Workflow Modules
  # -------------------------
  def includeWorkflow(self, *modules):
    """
    Includes all available workflow files related to the given list of workflow {modules}.
    Target files {module}.targ are loaded first. They should contain variables for the pipeline.
    Snakefiles {module}.sk are loaded afterwards. They should include Snakemake rules.A
    Ex: Including the workflow "fastq/trimming" and "fastq/adapters" will:
      - Load fastq/trimming.targ , fastq/adapters.targ
      - Cache fastq/trimming.sk   , fastq/adapters.sk
    """
    targets = [ f"{module}.targ" for module in modules ]
    skfiles = [ f"{module}.sk"   for module in modules ]
    self.includeWorkflowModules(*targets)
    self.snakefiles += skfiles

  def includeWorkflowModules(self, *modules, **kwargs):
    """ Includes the given module names if they exist. """
    self.includeModules(
      *list(
        [ module for module in modules if self.isModule(module) ]),
      **kwargs
    )

  def loadSnakefiles(self):
    self.includeWorkflowModules(*self.snakefiles, withConfigFiles=True)

  def loadWorkflow(self):
    self.formatAllTargets()
    self.loadSnakefiles()
    
  # ------------------
  # Fomatted Targets
  # 
  # This features allows to compose flexible formattable strings. 
  # Each can contain keywords from previously defined strings. 
  # All strings will can be later evaluated at once.
  # String names are then defined in Snakemake namespace.
  # ------------------
  def addTargets(self, **kwargs):
    """ Save the given strings and their associated values """
    self.targets.update(kwargs)
    for key, val in kwargs.items():
      self.namespace[key] = val

  def formatTargets(self, **kwargs):
    """ Format and declare the given target dict. """
    for key, val in kwargs.items():
      self.formatTarget(key, val)

  def formatTarget(self, key, value):
    kwVals = { key: self.namespace[key]  
               for key in StringFormatter(value).keywords()
             }
    self.namespace[key] = value.format(**kwVals)

  def formatAllTargets(self):
    """ Formats all the saved targets """
    self.formatTargets(**self.targets)

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

  # -----
  # Jobs
  # -----
  @property
  def jobExeBase(self):
    return f"{self.jobsExeDir}{os.path.sep}{self.jobExeTime()}_{self.config.pipeline.name}"

  @property
  def jobsExeDir(self):
    return f"jobs{os.path.sep}{self.exeTime}"

  def jobExeTime(self):
    return datetime.datetime.now().strftime('%H%M%S-%f')

  def checkJobsDir(self):
    os.makedirs(self.jobsExeDir, exist_ok=True)

  @property
  def jobName(self):
    """ 
    Returns the default job name. 
    Truncates the name to 13 chars as the old PBS jobs submission fails when 
    the requested job name is over 13 characters.
    """
    return f"{self.config.pipeline.name}-pypette"[:12]

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
