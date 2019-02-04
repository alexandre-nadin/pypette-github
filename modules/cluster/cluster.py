def cluster__prefixMountPoint(func):
  def wrapper(*args, **kwargs):
    mntpoint = pipeman.cluster_mnt_point.rstrip(os.path.sep)
    path = func(*args, **kwargs)
    if mntpoint:
      path = path.lstrip(os.path.sep) 
    return os.path.join(mntpoint, path)
  return wrapper
