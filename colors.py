#!/usr/bin/python
#print table header

import sys

colw = 10
bg_start = 40
bg_end = 48
fg_start = 30
fg_end = 38

print("Terminal color code lookup chart")
print("  \033[2;37;40m* add leading '\\033' and trailing 'm' to text in desired block\033[0m")
print("  \033[2;37;40m* remember to terminate with '\\033[0m'\033[0m")
for fg in range(fg_start, fg_end, 1):
	for mod in [2, 3, 1, 4]:
		#line = str(fg)
		#while ((len(line) % colw) != 0):
		#	line += " "
		line = ""
		for bg in range(bg_start, bg_end, 1):
			line += "\033[" + str(mod) + ";" + str(fg) + ";" + str(bg) + "m"
			tmp = " " + str(mod) + ";" + str(fg) + ";" + str(bg)
			while(len(tmp) < colw):
				tmp += " "
			line += tmp
			line += "\033[0m"
		print(line)
		
