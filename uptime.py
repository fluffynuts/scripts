import sys
import os
from datetime import datetime

class Uptime:
  def printUptime(self):
    lastbootstr = self._getLastBootStr()
    uptimeDelta = self._getUptimeDelta(lastbootstr)
    self._printUptime(uptimeDelta)

  def _printUptime(self, tdelta):
    printstring = self._getPrintString(tdelta)
    print(printstring)

  def _getPrintString(self, tdelta):
    seconds = self._zeroPad(tdelta.seconds % 60)
    minutes = self._zeroPad((tdelta.seconds % 3600) / 60)
    hours = tdelta.seconds / 3600
    return "Uptime: %i days, %i hours, %s minutes, %s seconds" % (tdelta.days, hours, minutes, seconds)

  def _zeroPad(self, i):
    s = str(i)
    prepend = []
    while len(s) < 2:
      s = "0" + s
    return s

  def _getUptimeDelta(self, timeString):
    lastboot = datetime.strptime(timeString, "%Y-%m-%d %H:%M:%S %p")
    return datetime.now() - lastboot

  def _getLastBootStr(self):
    for line in os.popen("net statistics workstation"):
      parts = filter(None, line.split(" "))
      if parts[0] == "Statistics":
        return (" ".join([parts[2], parts[3], parts[4]])).strip()
    return None


if __name__ == "__main__":
  Uptime().printUptime()
