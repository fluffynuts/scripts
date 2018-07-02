#!/usr/bin/python
#vim: expandtab
import sys
import os
import glob
import time

class SmartSaver:
  def __init__(self):
    self.watch_cmds = ["/usr/bin/mplayer", "/usr/bin/vlc"]
    #self.watch_cmds = ["gmplayer"]
    self.interval = 15
    self.proc_cache = dict()
    self.tmpprocs = []
    os.system("renice 5 " + str(os.getpid()))

  def run_cmd(self, cmd):
    if os.system(cmd):
      print "cmd fails: '" + cmd + "'"

  def poke_screensaver(self):
    print "Poking screensaver"
    if self.is_running("gnome-screensaver"):
      self.run_cmd("gnome-screensaver-command -p")
    if self.is_running("xscreensaver"):
      self.run_cmd("xscreensaver-command -deactivate")
    self.run_cmd("xset -dpms")

  def is_running(self, cmd):
    pids = []
    self.tmpprocs = glob.glob("/proc/*")
    self.tmpprocs.reverse()
    for f in self.tmpprocs:
      d = os.path.split(f)[1]
      try:
        pid = int(d)
        #print "Examining pid:", pid
        if self.proc_cache.has_key(pid):
          if self.proc_cache[pid] == cmd:
            #print "Using cached value for pid:", pid, "(" + cmd + ")"
            print cmd, "is running (cached)"
            return True
          else:
            continue

        if d == 10723 and cmd == 'vlc':
            print('foo')
        for line in open(os.path.join(f, "cmdline"), "r"):
          parts = line.split("\x00")
          self.proc_cache[pid] = parts[0]
          # look for the command in question (direct bin run)
          if parts[0] == cmd or os.path.split(parts[0])[1] == cmd:
            print cmd, "is running (1)"
            self.proc_cache[pid] = cmd
            return True
          # look for the command in question as a script
          #  (not required for my purposes, but may be useful
          #  at a later stage)
          if len(parts) > 1 and\
            (parts[1] == cmd or\
              os.path.split(parts[1])[1] == cmd):
            for idx in range(1, len(parts) - 1):
              if os.path.isfile(parts[idx]):
                for line in open(parts[idx], "r"):
                  if line.find("#!") == 0:
                    iparts = line.split(" ")
                    interp = iparts[0][2:]
                    if os.path.isfile(interp):
                      print(cmd, "is running (2)")
                      self.proc_cache[pid] = cmd
                      return True
                  else:
                    self.proc_cache[pid] = parts[idx]
                    break
          pids.append(pid)
      except Exception as ex:
          pass
    print(cmd + " is not running")
    return False

  def trim_cache(self, pids = []):
    if len(pids) == 0:
      for f in self.tmpprocs:
        d = os.path.split(f)[1]
        try:
          pid = int(d)
          pids.append(pid)
        except:
          pass
    for pid in self.proc_cache.keys():
      if pids.count(pid) == 0:
        del self.proc_cache[pid]

  def watch(self):
    last_poked = False
    while True:
      print("")
      poked = False
      self.tmpprocs = []
      for cmd in self.watch_cmds:
        print('checking on: ' + cmd)
        if self.is_running(cmd):
          self.poke_screensaver()
          poked = True
          break
      if last_poked and not poked:
        # re-enable the dpms features
        os.system("xset +dpms")
        os.system("xset dpms 1200 1500 1800")
      last_poked = poked
      time.sleep(self.interval)
      self.trim_cache()


if __name__ == "__main__":
  s = SmartSaver()
  s.watch()
