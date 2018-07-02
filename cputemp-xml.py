#!/usr/bin/python
import os
import sys
import xml.dom.minidom

def all_numeric(s):
	for c in s:
		if "01234567890".count(c) == 0:
			return False
	return True

if __name__ == "__main__":
	out = ""
	if len(sys.argv[1:]):
		out = sys.argv[1]
	doc = xml.dom.minidom.Document()
	docEl = doc.createElement("cputemp")
	doc.appendChild(docEl);
	for line in os.popen("sensors"):
		while line.count("  ") > 0:
			line = line.replace("  ", " ")
		parts = line.split(" ")
		if parts[0].strip("0123456789") != "Core":
			continue
		el = doc.createElement(parts[0])
		docEl.appendChild(el)
		tmp = parts[2]
		temp = ""
		for c in tmp:
			if ".1234567890".count(c) > 0:
				temp += c
		t = doc.createTextNode(temp)
		el.appendChild(t)
	
	x = doc.toprettyxml()
	if len(out) == 0:
		print(x)
	else:
		open(out, "w").write(x)
