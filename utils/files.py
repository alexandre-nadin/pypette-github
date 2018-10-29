#!/usr/bin/env python
import os
def extensionless(name):
  """
  Removes a file name's extensions.
  > extensionless('/path/to/file.ext1.ext2.ext3')
    /path/to/file
  """
  split = os.path.splitext(name)
  return basename(split[0]) if split[1] else split[0]
