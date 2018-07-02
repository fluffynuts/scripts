#!/usr/bin/python
import os
import shutil
from PushbulletMessage import MessagePusher

store_path = '/mnt/dump/install-src/cm12-i9300/rom'
serve_path = '/var/www/html/cm12'
urlBase = 'http://192.168.1.100/cm12/'
exe = 'code/xda-rom-downloader/source/xda-rom-downloader/bin/Debug/xda-rom-downloader.exe'
home = os.path.expanduser('~')
exe = os.path.join(home, exe)
status = os.system('%s -o %s' % (exe, store_path))
if status == 0:
    stored = os.listdir(store_path)
    served = os.listdir(serve_path)
    to_copy = list(set(stored) - set(served))
    for newFile in to_copy:
        print('pushing message about: ' + newFile)
        shutil.copyfile(os.path.join(store_path, newFile), os.path.join(serve_path, newFile))
        localUrl = urlBase + newFile
        pusher = MessagePusher()
        pusher.push("New ROM available", localUrl)
        
