#!/usr/bin/python

import sys
import os
import re


class Flattener:
	def __init__(self, basedir = None):
		self.basedir = basedir
		self.blankstr = 75 * " "

	def status(self, s):
		if (len(s) > 72):
			s = s[:72] + "..."
		sys.stdout.write("\r%s\r%s" % (self.blankstr, s))
		sys.stdout.flush()

	def ireplace(self,s,old,new,count=0):
		''' Behaves like string.replace(), but does so in a case-insensitive
		fashion. (scraped from 
		http://www.noogz.net/website/blog/programming/20080327-StringIRep.html)'''
		pattern = re.compile(re.escape(old),re.I)
		return re.sub(pattern,new,s,count)

	def flatten(self, dir = None):
		if dir == None:
			dir = self.basedir
		if dir == None:
			return False
		contents = self.ls_R(dir)
		dirlen = len(dir)
		if dirlen > 0 and dir[-1] != os.sep:
			dirlen += 1

		dirs = []
		i = 0
		for f in contents:
			if os.path.isdir(f):
				dirs.append(f)
				continue
			rel = f[dirlen:]
			#parts = os.path.split(rel)
			parts = rel.split(os.sep)
			basedir = parts[0]
			# try to remove the artist name from the file -- it's
			#		in the dirname
			parts[-1] = self.ireplace(parts[-1], basedir + " - ", "")
			if len(parts) > 1:
				# remove the album name from the file name if it's there
				parts[-1] = self.ireplace(parts[-1], parts[-2] + " - ", "")
			fname = " # ".join(parts[1:])
			newname = os.path.join(dir, basedir, fname)
			if newname != f:
				print("%s\n ->  %s" % (f, newname))
				os.rename(f, newname)
			if os.path.splitext(newname)[-1].lower() == ".ogg":
				self.convert_ogg_to_mp3(newname)

		basedirs = os.listdir(dir)
		for i in range(len(basedirs)):
			basedirs[i] = os.path.join(dir, basedirs[i])
		for d in sorted(dirs, reverse=True):
			if not os.path.isdir(d):
				continue
			if basedirs.count(d) > 0:
				continue
			if len(os.listdir(d)) == 0:
				print("del: %s" % (d))
				os.rmdir(d)
			else:
				print("%s not empty!" % (d))

		return True

	def convert_ogg_to_mp3(self, file):
		tmpfile = os.path.join("/tmp", os.path.basename(file) + ".raw")
		if os.system("oggdec \"%s\" -o \"%s\"" % (file, tmpfile)):
			print(" -- Can't convert %s to mp3: oggdec fails" % (file))
			return
		if os.system("lame --preset hifi \"%s\" \"%s\"" % (tmpfile, os.path.splitext(file)[0] + ".mp3")):
			print(" -- Can't convert %s to mp3: lame fails" % (file))
			return
		os.remove(tmpfile)
		os.remove(file)

	def ls_R(self, dir, include_dirs=False):
		stack = [dir]
		ret = []
		items = 0
		while stack:
			thisdir = stack.pop(0)
			for f in sorted(os.listdir(thisdir)):
				items += 1
				if items % 100 == 0:
					self.status("Listing directory contents... %i" % (items))
				path = os.path.join(thisdir, f)
				if os.path.isdir(path):
					ret.append(path)
					stack.append(path)
					continue
				ret.append(path)
		self.status("")
		return sorted(ret)

if __name__ == "__main__":
	f = Flattener()
	for arg in sys.argv[1:]:
		if os.path.isdir(arg):
			f.flatten(arg)
		else:
			print("%s: dir not found" % (arg))

