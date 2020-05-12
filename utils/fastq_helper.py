# python
import os
import sys
import re
import addict

class Field(object):
  """
  A field that is comprised in a FileName.
  """
  SEPARATOR      = '_'
  OPTIONAL       = True
  WITH_SEPARATOR = True

  def __init__(self, name, regex, optional=False, withSeparator=True):
    self.name          = name
    self.regexBase     = regex
    self.optional      = optional
    self.withSeparator = withSeparator
    self.match         = None

  @property
  def separator(self):
    return self.SEPARATOR if self.withSeparator else ""

  @property
  def optionalStr(self):
    return '?' if self.optional else ""

  @property
  def regex(self):
    """
    Builds the full regex string to match the fastq name.
    Takes optionaloty into account.
    """
    return f"({self.separator}{self.regexBase}){self.optionalStr}"

  @property
  def value(self):
    """ Returns the field value without field separator. """
    return self.match[1:] if self.match and self.withSeparator else self.match

  def valueNoSep(self, val):
    if val and self.withSeparator and val.startswith(self.SEPARATOR):
      return val[1:] 
    else:
      return val

  def valueWithSep(self, val):
    if val and self.withSeparator and not val.startswith(self.SEPARATOR):
      return self.SEPARATOR + val 
    else:
      return val

class FileName(object):
  """
  A FileName instance can comprise instances of Field, each one can be optional.
  This class tries to regex-match each field.
  """
  FIELDS = ()
  def __init__(self, fileName):
    self.fileName = fileName
    self.fullName = os.path.abspath(self.fileName)
    self.baseName = os.path.basename(self.fullName)
    self.isValid  = True
    self.ruleName = "expected"
    self.fields   = self.fieldsCls()
    self.matchFields()

  @property
  def name(self):
    return self.baseName

  def matchFields(self):
    """ Matches all the FileName's filename's fields to its full regex. """
    try:
      for field, match in zip(self.fields, re.search(self.regex, self.name).groups()):
        field.match = match
    except AttributeError as ae:
      self.isValid = False
      sys.stderr.write(f"File {self.fileName} doesn't seem to follow the {self.ruleName} naming convention.\n")

  @property
  def regex(self):
    """ Creates the whole fileName's regex string. """
    return self.regexFields(*self.fields)

  @classmethod
  def regexCls(cls):
    """ Creates the FileName class' regex string. """
    return cls.regexFields(*cls.fieldsCls())

  @classmethod
  def regexFields(cls, *fields):
    """ Creates the concatenated regex string from the given fields. """
    return ''.join((field.regex for field in fields))

  @classmethod
  def fieldsCls(cls):
    """ returns a tuple of Field object for each field of the class. """
    return tuple(Field(*field) for field in cls.FIELDS)

  def getField(self, name):
    """ Retrieves a field by the given :name: """
    try:
      return next( (field for field in self.fields if field.name==name) )
    except:
      return ()

  def fieldAttrs(self, *attrs):
    """ Creates a tuple of the object's field tuples with the given :attrs: field attributes. """
    return tuple(tuple(getattr(field, attr) for attr in attrs)
                 for field in self.fields)

  @classmethod
  def fieldAttrsCls(cls, *attrs):
    return tuple(tuple(getattr(field, attr) for attr in attrs)
                 for field in cls.fieldsCls())

  def setFieldsNameValue(self, names=[], values=[]):
    """ Sets the fields' given :values: for the given field :names: """
    for name, value in zip(names, values):
      self.getField(name).match = value

class IlluminaName(FileName):
  """
  Extends the FileName class. Redefines its own fields.
  """
  FIELDS = (
    ('sample_name'     , "\w+?"       , not Field.OPTIONAL, not Field.WITH_SEPARATOR),
    ('sample_number'   , "S\d+"       ,     Field.OPTIONAL,     Field.WITH_SEPARATOR),
    ('sample_lane'     , "L\d+"       ,     Field.OPTIONAL,     Field.WITH_SEPARATOR),
    ('sample_read'     , "R[12]"      , not Field.OPTIONAL,     Field.WITH_SEPARATOR),
    ('sample_chunknb'  , "\d+"        ,     Field.OPTIONAL,     Field.WITH_SEPARATOR),
    ('sample_extension', "\.fastq\.gz", not Field.OPTIONAL, not Field.WITH_SEPARATOR),
  )

  def __init__(self, fileName):
    super(IlluminaName, self).__init__(fileName)
    self.ruleName = "Illumina"

def chunkNameRegex():
  return IlluminaName.regexCls().rstrip(sampleExtensionField().regex)

def chunkNameVal(s):
  return s.rstrip(sampleExtensionField().regex)

def sampleExtensionField():
  return next(filter(lambda x: x.name=='sample_extension', IlluminaName.fieldsCls() ))

class PathName(FileName):
  """
  Extends the FileName class. Redefines its own fields.
  It is not a real filename but it makes use of FileName methods to match extra fields
  that are not conventional in an Illumina name.
  """
  FIELDS = (
    ('sample_run'      , "[\w-]+"        , not Field.OPTIONAL, not Field.WITH_SEPARATOR),
    ('sample_path'     , "\w+"           , not Field.OPTIONAL, not Field.WITH_SEPARATOR),
    ('sample_basename' , "\w+"           , not Field.OPTIONAL, not Field.WITH_SEPARATOR),
    ('sample_chunkname', chunkNameRegex(), not Field.OPTIONAL, not Field.WITH_SEPARATOR),
  )

  def __init__(self, fileName, runId):
    super(PathName, self).__init__(fileName)
    self.setFieldsNameValue(
      [ field.name for field in self.fields ],
      [ runId, self.fileName, self.baseName, None])

  def matchFields(self):
    """
    This class is not abou Illumina convention.
    This method has to be disabled otherwise it will be set as an unvalid file.
    """
    pass


class FastqFile(object):
  """
  This class helps to get a fastq file name's information.
  The file should respect Illumina filename convention:
    /path/to/SampleName_SampleNumber_LaneNumber_ReadNumber_ChunkNumber.fastq_extension.
  The basename will be considered.
  Fields can be optional except for SampleName and ReadNumber.
  A FastqFile instance is comprisd of an IlluminaFile and a PathName instances.

  """

  def __init__(self, fileName, runId=""):
    self.fileName     = fileName
    self.runId        = runId
    self.illuminaName = IlluminaName(fileName)
    self.pathName     = PathName(fileName, runId)
    self.pathName.setFieldsNameValue(
      ['sample_chunkname'], [ chunkNameVal(self.illuminaName.baseName)] )

  @property
  def isValid(self):
    return self.illuminaName.isValid and self.pathName.isValid

  @property
  def fields(self):
    return self.illuminaName.fields + self.pathName.fields

  def fieldAttrs(self, *attrs):
    return self.illuminaName.fieldAttrs(*attrs) + self.pathName.fieldAttrs(*attrs)

  @classmethod
  def fieldAttrsCls(cls, *attrs):
    return IlluminaName.fieldAttrsCls(*attrs) + PathName.fieldAttrsCls(*attrs)
 
  @classmethod
  def fieldsCls(cls):
    return IlluminaName.fieldsCls() + PathName.fieldsCls()

  @classmethod
  def fieldsFilter(cls, name):
    return [ field for field in cls.fieldsCls() if field.name==name ]
 
  @classmethod
  def fieldNoSepCls(cls, field, val):
    fqFields = cls.fieldsFilter(field)
    if fqFields:
      return fqFields[0].valueNoSep(val)
    else:
      return val

  @classmethod
  def fieldWithSepCls(cls, field, val):
    fqFields = cls.fieldsFilter(field)
    if fqFields:
      return fqFields[0].valueWithSep(val)
    else:
      return val
