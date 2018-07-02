#!/usr/bin/python
import sys
import os
from pushbullet import Pushbullet
import ConfigParser
import dropbox

class Pusher:
  def __init__(self):
    self._loadConfig()

  def _loadConfig(self):
    home = os.path.expanduser('~')
    self._secretsFile = os.path.join(home, 'secrets.ini')
    self._loadConfigFile()

  def _loadConfigFile(self):
    cfg = ConfigParser.ConfigParser()
    cfg.read(self._secretsFile)
    self._initDropbox(cfg)
    self._initPushbullet(cfg)

  def _initPushbullet(self, cfg):
    section = 'pushbullet'
    self._pbToken = cfg.get(section, 'token')
    self._pbDevice = int(cfg.get(section, 'device'))

    

  def _initDropbox(self, cfg):
    section = 'dropbox'
    self._key = cfg.get(section, 'key')
    self._secret = cfg.get(section, 'secret')
    if cfg.has_option(section, 'token'):
        self._token = cfg.get(section, 'token')
    else:
        self._token = self._authorize()
        self._setPersistentToken(cfg, section, self._token)


  def _setPersistentToken(self, cfg, section, token):
        cfg.set(section, 'token', token)
        fp = open(self._secretsFile, 'w')
        fp.truncate()
        cfg.write(fp)

  def _authorize(self):
    flow = dropbox.client.DropboxOAuth2FlowNoRedirect(self._key, self._secret)
    authorize_url = flow.start()
    print '1. Go to: ' + authorize_url
    print '2. Click "Allow" (you might have to log in first)'
    print '3. Copy the authorization code.'
    auth_token = raw_input("Enter the authorization code here: ").strip()
    access_token, user_id = flow.finish(auth_token)
    print(access_token)
    print(user_id)
    return access_token

  def push(self, path):
    url = self._pushToDropbox(path)
    self._pushToPushbullet(url)

  def _pushToDropbox(self, path):
    client = dropbox.client.DropboxClient(self._token)
    print('uploading %s...' % (path))
    uploadName = os.path.basename(path)
    with open(path, 'r') as fp:
        response = client.put_file(uploadName, fp, overwrite=True)
        print('upload complete!')
        m = client.metadata(uploadName)
        return client.share(m['path'])['url']

  def _pushToPushbullet(self, url):
      pb = Pushbullet(self._pbToken)
      device = pb.devices[self._pbDevice]
      device.push_note('New ROM!', url)


if __name__ == '__main__':
  pusher = Pusher()
  for arg in sys.argv[1:]:
    print('%s:%s' % (arg, pusher.push(arg)))
