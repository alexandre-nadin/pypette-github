def cluster__prefixMountPoint(func):
  def wrapper(*args, **kwargs):
    mntpoint = pypette.clusterMntPoint.rstrip(os.path.sep)
    path = func(*args, **kwargs)
    if mntpoint:
      path = path.lstrip(os.path.sep) 
    return os.path.join(mntpoint, path) if path else None
  return wrapper
