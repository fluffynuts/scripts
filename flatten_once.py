#!/usr/bin/python
import os
import sys

class Flattener:
  def __init__(self, options = {}):
    self.blankstr = 75 * " "
    self.options = {
    }
    for opt in options:
      self.options[opt] = options[opt]

  def process(self, baseFolder):
    allFiles = self.ls_R(baseFolder)
    for path in allFiles:
      if os.path.isdir(path):
        continue
      fileName = os.path.basename(path)
      folder = os.path.dirname(path)
      parent = os.path.dirname(folder)
      if not parent.startswith(baseFolder):
        print('Can\'t flatten "' + folder + '"')
        print('fileName: ' + fileName)
        print('folder: ' + folder)
        print('parent: ' + parent)
        continue
      folderName = os.path.basename(folder)
      newFolder = parent + ' - ' + folderName
      if not os.path.isdir(newFolder):
        os.mkdir(newFolder)
      newFile = os.path.join(newFolder, fileName)
      print(path + ' -> ' + newFile)
      os.rename(path, newFile)
    self.removeAllEmptyFoldersUnder(baseFolder)

  def removeAllEmptyFoldersUnder(self, baseFolder):
    deletedSomething = True
    while deletedSomething:
      deletedSomething = False
      for path in self.ls_R(baseFolder):
        if not os.path.isdir(path):
          continue
        if len(os.listdir(path)) == 0:
          try:
            os.rmdir(path)
            deletedSomething = True
          except Exception as e:
            print('Can\'t remove "' + path + '": ' + e.strerror)

  def ls_R(self, dir, include_dirs=False):
    stack = [dir]
    ret = []
    items = 0
    while stack:
      thisdir = stack.pop(0)
      for f in sorted(os.listdir(thisdir)):
        items += 1
        if items % 100 == 0:
          self.status('Listing directory contents... %i' % (items))
        path = os.path.join(thisdir, f)
        if os.path.isdir(path):
          ret.append(path)
          stack.append(path)
          continue
        ret.append(path)
    self.status('')
    return sorted(ret)

  def status(self, s):
    if (len(s) > 72):
      s = s[:72] + "..."
    sys.stdout.write("\r%s\r%s" % (self.blankstr, s))
    sys.stdout.flush()


if __name__ == '__main__':
  flattener = Flattener()
  if len(sys.argv[1:]) == 0:
    print('Please specify one or more base folders to work on')
  for arg in sys.argv[1:]:
    flattener.process(arg)
