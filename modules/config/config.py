def config__msgErrorConfigFiles():
  return """Please produce config files with the config pipeline:
    $ ctgb-pipe --prj {prj} -p config -o config/<FILE>
    $ ctgb-pipe --prj {prj} -p config -o config/all.done
  """.format(prj=pipeman.project)

def config__setConfigs(**kwargs):
  """
  Not elegant way to deal with config files.
  Should set dependence to cluster.yaml (retreived in metadata.json)
  Loads metadata.json.
  """

  """ Load configurations for cluster, project and pipeline """
  error = False
  for conf in config__config_files:
    if os.path.exists(conf) and os.path.isfile(conf):
      pipeman.config_manager.loadConfig(conf)
    else:
      pass
      #if pipeman.pipe_name != config__dir:
      #  pipeman.log.error("Config file '{}' missing.".format(conf))
      #  error = True
  if error:
    pipeman.log.error(config__msgErrorConfigFiles())
    raise
