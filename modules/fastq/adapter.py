pipeman.includeModule("cluster/cluster.py")

@cluster__prefixMountPoint
def fastq_adapter__toolAdapters(trimmingTool):
  """
  Retrieves the cluster's path to the given :trimmingTool: 's adapters.
  """
  return os.path.join(
    pipeman.config.cluster.adapterDir,
    pipeman.config.pipeline.modules.fastq.adapters[trimmingTool]
  )
