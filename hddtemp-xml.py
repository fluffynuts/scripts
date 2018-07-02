#!/usr/bin/python
import os
import sys
import xml.dom.minidom

def all_numeric(s):
	for c in s:
		if "01234567890".count(c) == 0:
			return False
	return True

def get_temp(drive):
	cmd = "/usr/sbin/hddtemp " + drive
	fp = os.popen(cmd, "r")
	ret = ""
	line = fp.readline()
	in_temp = False
	idx = -1
	nums = ".0123456789"
	while (len(line) + idx) > 0:
		if nums.find(line[idx]) > -1:
			break
		idx -= 1
	while (len(line) + idx) > 0:
		if nums.find(line[idx]) > -1:
			ret = line[idx] + ret
		else:
			break
		idx -= 1
	return ret

if __name__ == "__main__":
	out = ""
	drives = []
	lastarg = ""
	for arg in sys.argv[1:]:
		if ["-o"].count(arg) > 0:
			lastarg = arg
		elif lastarg == "-o":
			out = arg
			lastarg = ""
		elif lastarg == "":
			if arg[:5] != "/dev/" and not os.path.exists(arg):
				arg = "/dev/" + arg
			drives.append(arg)
		else:
			print("Unrecognised argument '" + arg + "'")
			sys.exit(1)
	
	if len(drives) == 0:
		print("You must specify at least one drive on the commandline")
		sys.exit(1)

	doc = xml.dom.minidom.Document()
	docEl = doc.createElement("hddtemp")
	doc.appendChild(docEl);
	for d in drives:
		temp = get_temp(d)
		if len(temp) == 0:
			print("Can't get temp for '" + d + "'; skipping");
			continue
		el = doc.createElement(os.path.basename(d))
		docEl.appendChild(el)
		t = doc.createTextNode(temp)
		el.appendChild(t)
	
	x = doc.toprettyxml()
	if len(out) == 0:
		print(x)
	else:
		open(out, "w").write(x)
