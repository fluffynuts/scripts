#!/usr/bin/python
# vim: expandtab shiftwidth=2 tabstop=2
import os
import sys
try:
	import psyco
except:
	pass
import time
blankstr = ""
ls_label = ""

def ls_R(dir):
  ls = [dir]
  os.path.walk(dir, walk_cb, ls)
  ls = ls[1:]
  sys.stdout.write("\r" + blankstr + "\r")
  sys.stdout.flush()
  ls.sort()
  return ls

def walk_cb(ls, dirname, fnames):
  global ls_label
  d = dirname[len(ls[0]):]
  master_len = len(ls[0]) + 1
  for f in fnames:
    fpath = os.path.join(dirname, f)
    if os.path.isfile(fpath):
      ls.append(fpath[master_len:])
      items = len(ls) - 1
      if items % 100 == 0:
        sys.stdout.write("\r" + blankstr + "\r%s : %s files found..." %(ls_label, str(items)))
        sys.stdout.flush()

def usage():
  print("Usage: " + os.path.basename(sys.argv[0]) + " {dir1} {dir2}")
  sys.exit(0)

def get_hr_time(t):
  t = int(t)
  min = str(t / 60)
  secs = str(t % 60)
  if len(min) < 2:
    min = "0" + min
  if len(secs) < 2:
    secs = "0" + secs
  return min + ":" + secs

def get_new(label, reference, compare):
  global blankstr
  ret = []
  idx = 0
  count = len(compare)
  for f in compare:
    idx += 1
    if reference.count(f) == 0:
      ret.append(f)
    if idx % 100 == 0:
      perc = (idx * 100.0) / count
      status("%s: %i%%" % (label, int(perc)))
  ret.sort()
  return ret

def get_removed(label, reference, compare):
  global blankstr
  ret = []
  idx = 0
  count = len(reference)
  for f in reference:
    idx += 1
    if compare.count(f) == 0:
      ret.append(f)
    if idx % 100 == 0:
      perc = (idx * 100.0) / count
      status("%s: %i%%" % (label, int(perc)))
  return ret

def clear_line():
  global blankstr
  sys.stdout.write("\r%s\r" % blankstr)

def print_list(label, ref_list, dlist, out_file):
  if len(dlist) == 0:
    return
  if len(out_file):
    try:
      fp = open(out_file, "ab")
      fp.write("========\n" + label + "========\n")
      for f in dlist:
        fp.write("  %s\n" % (f))
      fp.close()
    except Exception, e:
      print(str(e))
  else:
    print(label)
    for f in dlist:
      print("  %s" % (f))

def status(s):
  sys.stdout.write("\r%s\r%s" % (blankstr, s))
  sys.stdout.flush()

def main():
  global blankstr
  blankstr = ""

  if len(sys.argv) == 0:
    usage()

  for i in range(76):
    blankstr += " "
  
  left_dirs = []
  right_dirs = []
  last_arg = ""
  out_file = ""
  for arg in sys.argv[1:]:
    if ["-l", "-r", "-o"].count(arg) > 0:
      last_arg = arg
      continue
    if last_arg == "-o":
      out_file = arg
      try:
        fp = open(out_file, "wb")
        fp.close()
      except Exception, e:
        print(str(e))
    if os.path.isdir(arg):
      if last_arg == "":
        if len(left_dirs) == 0:
          left_dirs.append(arg)
          continue
        if len(right_dirs) == 0:
          right_dirs.append(arg)
          continue
        print("Left and right dirs already defined; for multiple dirs use")
        print(" -l <dir> <dir> ... -r <dir> <dir>")
        sys.exit(1)
      if last_arg == "-r":
        right_dirs.append(arg)
        continue
      if last_arg == "-l":
        left_dirs.append(arg)
  if len(left_dirs) == 0:
    print("No left dir(s) defined")
    sys.exit(1)
  if len(right_dirs) == 0:
    print("No right dir(s) defined")
    sys.exit(1)
  start = time.time()
  left_list = []
  right_list = []
  if len(left_dirs) > 0:
    s = "s"
  else:
    s = ""
  print("\r%s\rListing contents under left dir%s" % (blankstr, s))
  global ls_label
  for d in left_dirs:
    ls_label = "Scanning %s" % d
    tmp = ls_R(d)
    if len(tmp) > 0:
      left_list.extend(tmp)
  if len(right_dirs) > 0:
    s = "s"
  else:
    s = ""
  print("Left dirs scanned: %i files found" % len(left_list))
  status("Listing contents under right dir%s" % (s))
  for d in right_dirs:
    ls_label = "Scanning %s" % d
    tmp = ls_R(d)
    if len(tmp) > 0:
      right_list.extend(tmp)
  clear_line()
  print("Right dirs scanned: %i files found" % len(right_list))
  right_new = get_new("-> Calculating missing from left", left_list, right_list)
  clear_line()
  print_list("Missing from left:", right_dirs, right_new, out_file)
  left_new = get_new("-> Calculating missing from right", right_list, left_list)
  clear_line()
  print_list("Missing from right:", left_dirs, left_new, out_file)
  if len(left_new) + len(right_new) == 0:
    print("left and right match up!")
  else:
    print("%i files missing from right" % len(left_new))
    print("%i files missing from left" % len(right_new))
  runtime = int(time.time() - start);
  print("Run time: " + get_hr_time(runtime))
  
if __name__ == "__main__":
  try:
    main()
  except KeyboardInterrupt:
    print("\n (Aborted)")
  except Exception, e:
    print("\n FAIL: %s" % str(e))

