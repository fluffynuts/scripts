#!/usr/bin/python
import os
import sys
import sqlite3
import ConfigParser

def pad(s, w = 60):
  while (len(s) < w):
    s += " "
  return s

def vacuum(db):
  sys.stdout.write(pad("  Vacuuming %s" % (os.path.basename(db))))
  sys.stdout.flush()
  try:
    c = sqlite3.connect(db)
    c.executescript("vacuum;")
    sys.stdout.write("(ok)\n")
  except Exception, e:
    sys.stdout.write("(fail)\n")
    print(str(e))

def vacuum_profile(ppath):
  for f in os.listdir(ppath):
    if os.path.splitext(f)[1] == ".sqlite":
      f = os.path.join(ppath, f)
      vacuum(f)

if __name__ == "__main__":
  if (sys.platform == "win32" or sys.platform == "win64"):
    pbase = os.path.join(os.path.expanduser("~"), "Application Data", "Mozilla", "Firefox")
  else:
    pbase = os.path.join(os.path.expanduser("~"), ".mozilla", "firefox")
  pini = os.path.join(pbase, "profiles.ini")
  pcfg = ConfigParser.ConfigParser()
  pcfg.readfp(open(pini, "r"))
  pidx = 0

  while True:
    psection = ("Profile%i" % pidx)
    if not pcfg.has_section(psection):
      break
    pname = pcfg.get(psection, "name")
    ppath = pcfg.get(psection, "path").replace("/", os.sep)
    ppath = os.path.join(pbase, ppath)
    print("Profile: %s" % pname)
    vacuum_profile(ppath)
    pidx += 1
