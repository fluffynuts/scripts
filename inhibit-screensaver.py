#!/usr/bin/python
import dbus
import time

bus = dbus.Bus(dbus.Bus.TYPE_SESSION)
devobj = bus.get_object('org.gnome.ScreenSaver', '/org/gnome/ScreenSaver')
dev = dbus.Interface(devobj, "org.gnome.ScreenSaver")
cookie = dev.Inhibit('inhibit-screensaver.py', 'client request')
time.sleep(0)
dev.UnInhibit(cookie)
