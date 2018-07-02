#!/usr/bin/python
import sys
import os
from pushbullet import Pushbullet
import ConfigParser
import dropbox

class MessagePusher:
  def __init__(self):
    self._loadConfig()

  def _loadConfig(self):
    home = os.path.expanduser('~')
    self._secretsFile = os.path.join(home, 'secrets.ini')
    self._loadConfigFile()

  def _loadConfigFile(self):
    cfg = ConfigParser.ConfigParser()
    cfg.read(self._secretsFile)
    self._initPushbullet(cfg)

  def _initPushbullet(self, cfg):
    section = 'pushbullet'
    self._pbToken = cfg.get(section, 'token')
    self._pbDevice = int(cfg.get(section, 'device'))

  def push(self, subject, message):
    self._pushToPushbullet(subject, message)

  def _pushToPushbullet(self, subject, message):
      pb = Pushbullet(self._pbToken)
      device = pb.devices[self._pbDevice]
      device.push_note(subject, message)


if __name__ == '__main__':
  if len(sys.argv[1:]) < 2:
      print("Usage: %s <subject> <message>" % (sys.argv[0]))
      sys.exit(1)
  pusher = MessagePusher()
  pusher.push(sys.argv[1], sys.argv[2])
  
