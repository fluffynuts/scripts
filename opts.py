#!/bin/false
# CLI options helper

import os
import sys

class Options:
  def __init__(self, UsageHeader = "", UnconsumedHelp = ""):
    self.options = dict()
    # put something like "MyApp V1.2.3.4" here
    self.UsageHeader = UsageHeader
    # help for trailing arguments which do not have an argument spec, such as an expected URI or filename
    self.UnconsumedHelp = UnconsumedHelp
    self.cols = self.GetConsoleCols()
    self.unconsumed = []
    self.AddOpt("-h", "Help for this application", aliases=["-?", "/?"], consumes=0)
    self.AddOpt("--help", "More verbose help (including option aliases)", consumes=0)
    self.UsageOnBadArg = False
    self.UsageOnNoArgs = False
    self.ShortUsageHidesAliases = True

  def GetConsoleCols(self):
    try:
      if sys.platform == "win32" or sys.platform == "win64":
        # taken from http://code.activestate.com/recipes/440694/
        from ctypes import windll, create_string_buffer
        h = windll.kernel32.GetStdHandle(-12)
        csbi = create_string_buffer(22)
        res = windll.kernel32.GetConsoleScreenBufferInfo(h, csbi)
        if res:
          import struct
          (bufx, bufy, curx, cury, wattr, left, top, right, bottom, maxx, maxy) = struct.unpack("hhhhHhhhhhh", csbi.raw)
          return right-left -1
        else:
          return 78
      elif sys.platform == "posix":
        import struct, fcntl, termios
        s = struct.pack("HHHH", 0, 0, 0, 0)
        x = fcntl.ioctl(1, termios.TIOCGWINSZ, s)
        width = struct.unpack("HHHH", x)[1]
        if width < 80:
          width = 78
        return width -2
      else:
        return 80
    except Exception as e:
      print("Can't determine console columns (" + str(e) + "); Defaulting to 80")
      return 78

  def AddOpt(self, opt, help = "(no help)", aliases = [], consumes = 0, 
      ConsumesHelp = "", Default="", ShortHelp="", required=False, DataType="string",
      PrependShortHelp=True, ValidValues=[], LowerValues=False):
    if consumes == 0 and len(ConsumesHelp) > 0:
      # Default consumes value to number of items in the help listing
      consumes = len(ConsumesHelp.split(" " ))
    if consumes != 1 and Default == "":
      Default = []
    o = self.Option(opt, help, aliases, consumes, ConsumesHelp, Default, ShortHelp, DataType)
    o.required = required
    o.ValidValues = ValidValues
    o.LowerValues = LowerValues
    self.options[opt] = o

  def _print(self, s, indent = 0):
    words = s.split(" ")
    line = ""
    while (len(words)):
      if len(words[0]) + len(line) > self.cols:
        print((" " * indent) + line)
        line = ""
      if len(line) > 0:
        line += " "
      line += words[0]
      words = words[1:]
    if len(line):
      print((" " * indent) + line)

  def GetMaxLHSW(self, SkipAliases=False):
    lhsw = 0
    opts = self.options.keys()
    for o in opts:
      self.options[o].cols = self.cols
      self.options[o].prepare(SkipAliases)
      if self.options[o].lhsw > lhsw:
        lhsw = self.options[o].lhsw
    if lhsw > (self.cols / 2):
      lhsw = self.cols / 2
    return lhsw

  def Usage(self, Long=False):
    # make sure cols are up to date
    self.cols = self.GetConsoleCols()
    
    if (len(self.UsageHeader)):
      self._print(self.UsageHeader)
    tmp = ""
    opts = sorted(self.options.keys())
    if len(opts):
      tmp = " {options}"
    self._print("Usage: " + os.path.basename(sys.argv[0]) + tmp + " " + self.UnconsumedHelp)
    if len(opts):
      self._print("where options are of:", 1)
    if Long:
      SkipAliases = False
    else:
      SkipAliases = self.ShortUsageHidesAliases
    lhsw = self.GetMaxLHSW(SkipAliases)

    for o in opts:
      self.options[o].lhsw = lhsw
      self.options[o].Usage(Long, SkipAliases=SkipAliases)

    if Long:
      self._print("data types:", 1)
      self._print("bool:   yes/no/true/false/1/0", 2)
      self._print("string: any characters", 2)
      self._print("int:    any whole numeric value", 2)
      self._print("float:  any numeric value", 2)
  
  def BoolToStr(self, b):
    if b:
      return "True"
    else:
      return "False"

  def Dump(self):
    opts = sorted(self.options.keys())
    for o in opts:
      print(o)
      opt = self.options[o]
      print(" required: " + self.BoolToStr(opt.required))
      print(" selected: " + self.BoolToStr(opt.selected))
      print(" value:    " + str(opt.value))
      print(" Default:  " + str(opt.Default))

  def CheckType(self, val, opt):
    try:
      if opt.DataType == "string" or opt.DataType == "str":
        return str(val)
      if opt.DataType == "int":
        return int(val)
      if opt.DataType == "float":
        return float(val)
      if opt.DataType == "file":
        if not os.path.isfile(val):
          print("Option '%s' requires (an) existing file(s) for data ('%s' is invalid)" % (opt.opt, val))
          sys.exit(1)
        else:
          return val
      if opt.DataType == "dir":
        if not os.path.isdir(val):
          print("Option '%s' requires (an) existing folder(s) for data ('%s' is invalid)" % (opt.opt, val))
          sys.exit(1)
        else:
          return val
      if opt.DataType == "bool" or opt.DataType == "boolean":
        arg = arg.lower()
        if ["yes", "true", "1"].count(arg) > 0:
          return True
        else:
          return False
    except Exception as e:
      print("Option '" + opt.opt + "' requires an option of type '" + opt.DataType + "'")
      sys.exit(1)
    raise Exception("Unhandled DataType '" + opt.DataType + "' for option '" + opt.opt + "'")

  def ParseArgs(self):
    if self.UsageOnNoArgs and len(sys.argv[1:]) == 0:
      self.Usage()
      return False

    # take advantage of python's objects-by-reference schema
    last_consumer = None
    opts = list(self.options.keys())
    for o in self.options.keys():
      for a in self.options[o].aliases:
        opts.append(a)

    for arg in sys.argv[1:]:
      if arg == "-h":
        self.Usage(False)
        sys.exit(0)
      if arg == "--help":
        self.Usage(True)
        sys.exit(0)
      if arg == "--":
        last_consumer = None
        continue
      if opts.count(arg) == 0:
        if last_consumer == None:
          if len(arg) and (arg[0] == "-") and self.UsageOnBadArg:
            self._print("Bad option / argument: \"%s\"\n" % arg)
            self.Usage()
            return False
          self.unconsumed.append(arg)
      elif (sys.argv[1:].count("--") == 0): 
        # accept as the start of a new switch if the user has NOT employed
        #   explicit option argument ending (--)
        last_consumer = None
      
      if last_consumer == None:
        for opt_key in self.options.keys():
          o = self.options[opt_key]
          if o.Match(arg):
            last_consumer = o
            last_consumer.selected = True;
            if last_consumer.consumes == 0:
              last_consumer = None
            found = True
            break
      else:
        if not last_consumer.Valid(arg):
          self._print("Bad value for option '%s': %s" % (last_consumer.opt, arg))
          self._print("Acceptable values are:")
          for v in last_consumer.ValidValues:
            self._print(v, 2)
          sys.exit(1)
        if last_consumer.consumes < 2 and last_consumer.consumes > 0:
          last_consumer.SetValue(self.CheckType(arg, last_consumer))
          last_consumer = None
        else:
          if (last_consumer.consumes == -1) or (len(last_consumer.value) < last_consumer.consumes):
            last_consumer.AppendValue((self.CheckType(arg, last_consumer)))
          else:
            self._print("Option '%s' has too many arguments specified" % last_consumer.opt)
            self.Usage()
    return True

  def RequiredMissing(self):
    missing = dict()
    for o in self.options.keys():
      opt = self.options[o]
      if opt.required:
        if not opt.selected:
          missing[o] = opt
        elif opt.consumes == 1 and opt.value == "":
          missing[o] = opt
        elif (opt.consumes > 1) and (opt.consumes != len(opt.value)):
          missing[o] = opt
        elif (self.options[o].consumes == -1) and (len(opt.value) == 0):
          missing[o] = opt

    missing_opts = list(missing.keys())
    if len(missing_opts):
      missing_opts.sort()
      if len(missing_opts) == 1:
        s = " was"
      else:
        s = "s were"
      errmsg = "\nThe following required option" + s + " not supplied or fully qualified:\n\n"
      self.cols = self.GetConsoleCols()
      lhsw = self.GetMaxLHSW()
      for o in missing_opts:
        missing[o].lhsw = lhsw
        errmsg += missing[o].Usage(SkipAliases=True, ReturnAsString=True)
      print(errmsg)
      return True
    return False

  def validate(self, opt):
    opts = list(self.options.keys())
    if opts.count(opt) == 0:
      raise Exception("Option '" + opt + "' not handled by Options class")

  def value(self, opt):
    self.validate(opt)
    return self.options[opt].value 

  def selected(self, opt):
    self.validate(opt)
    return self.options[opt].selected

  def selectedOptions(self):
    ret = []
    for opt in list(self.options.keys()):
      if self.selected(opt):
        ret.append(opt)
    return ret

  class Option:
    def __init__(self, opt, help, aliases, consumes, ConsumesHelp, Default, ShortHelp,
        DataType="string", PrependShortHelp=True):
      self.opt = opt
      self.DataType = DataType.lower()
      self.consumes = consumes
      self.aliases = aliases
      self.help = help
      self.ShortHelp = ShortHelp
      self.ConsumesHelp = ConsumesHelp
      self.lhsw = 0
      self.rhsw = 0
      self.cols = 0
      self.selected = False
      self.required = False
      self.newline_before_help = False
      self.Default = Default
      self.PrependShortHelp = PrependShortHelp
      self.ValidValues = []
      self.LowerValues = False
      self.value = Default
      self.indent = 2

    def Valid(self, val):
      if len(self.ValidValues) == 0:
        return True
      elif self.LowerValues:
        if self.ValidValues.count(val) > 0:
          return True
        else:
          return False

    def Match(self, arg):
      if self.opt == arg:
        return True
      for a in self.aliases:
        if a == arg:
          return True
      return False

    def AppendValue(self, val):
      if self.LowerValues:
        self.value.append(val.lower())
      else:
        self.value.append(val)

    def SetValue(self, val):
      if self.LowerValues:
        self.value = val.lower()
      else:
        self.value = val

    def prepare(self, SkipAliases=False):
      self.lhsw = self.leftw(SkipAliases)
      self.sanitise_leftw()

    def sanitise_leftw(self):
      if self.lhsw > (self.cols / 2):
        self.lhsw = 0
        self.newline_before_help = True

    def leftw(self, SkipAliases=False):
      """Returns the minimum colwidth required to display the
          LHS of the help for this option"""
      self.aliases.sort()
      w = len(self.opt) + len(self.ConsumesHelp) + 1
      if not SkipAliases:
        for a in self.aliases:
          ll = len(a) + len(self.ConsumesHelp) + 1
          if ll > w:
            w = ll
      return w + self.indent + 2

    def pad(self, s, w, padwith = " "):
      while len(s) < w:
        s += padwith
      return s

    def format_rhs(self, s):
      lines = []
      words = s.split(" ")
      current_line = (self.indent * " ") + (" " * self.lhsw) 
      force_newline = 0
      while len(words):
        word = words[0].strip("\r")
        if word.count("\n") > 0:
          parts = word.split("\n")
          words = words[1:]
          words.insert(0, word[len(parts[0])+1:])
          word = parts[0]
          words.insert(0, word)
          force_newline = 1
        elif force_newline == 1:
          force_newline = 2
        if len(word) and word[0] == "\"" and word.count("\"") == 1:
          # try to keep a quoted string together
          tmp = [word]
          for w in words[1:]:
            tmp.append(w)
            if w.count("\"") == 1:
              break
          word = " ".join(tmp)
          if len(tmp) == len(words):
            words = []
          else:
            words = words[:len(tmp)]
          words = words[:len(tmp)]
        if len(word) + len(current_line) >= self.cols or force_newline == 2:
          if len(lines) == 0:
            current_line = current_line[self.lhsw + self.indent:]
          lines.append(current_line)
          current_line = (self.indent * " ") + (" " * self.lhsw)
        if len(current_line):
          current_line += " "
        current_line +=  word
        words = words[1:]
        if force_newline == 2: 
          force_newline = 0
      if len(lines) == 0:
        current_line = current_line[self.lhsw + self.indent:]
      if len(current_line.strip()) > 0:
        lines.append(current_line)
      return "\n".join(lines)
      
    def Usage(self, Long=False, SkipAliases=False, ReturnAsString = False):
      """Prints out usage for this option"""
      if self.lhsw == 0:
        self.lhsw = self.leftw()
      self.sanitise_leftw()
      if self.cols == 0:
        self.cols = 80
      if self.rhsw == 0:
        self.rhsw = self.cols - self.lhsw
      self.aliases.sort()
      s = self.opt
      if len(self.ConsumesHelp) > 0:
        s += " " + self.ConsumesHelp
      s = self.pad(s, self.lhsw - self.indent)
      lhspad = "\n" + (" " * (self.lhsw + self.indent))
      ret = (" " * self.indent) + s
      if not SkipAliases:
        sorted_aliases = []
        matched = True
        dashcount = 1
        while (matched):
          matched = False
          head = dashcount * "-"
          sublist = []
          for alias in self.aliases:
            if alias[:dashcount] == head and alias[dashcount] != "-":
              matched = True
              sublist.append(alias)
          sublist.sort()
          sorted_aliases += sublist
          dashcount += 1
        prepend = []
        for a in self.aliases:
          if sorted_aliases.count(a) == 0:
            prepend.append(a)
        prepend.sort()
        sorted_aliases = prepend + sorted_aliases
        for a in sorted_aliases:
          a = (" " * (self.indent + 1)) + a
          if len(self.ConsumesHelp):
            a += " " + self.ConsumesHelp
          ret += "\n" + self.pad(a, self.lhsw)
      if (self.newline_before_help):
        ret += lhspad
      if Long or len(self.ShortHelp) == 0:
        if self.PrependShortHelp and len(self.ShortHelp) > 0:
          ret += self.format_rhs(self.ShortHelp) + lhspad
        formatted_help = self.format_rhs(self.help)
        ret += self.format_rhs(self.help)
        if Long:
          if self.Default == None or self.Default == [] or len(str(self.Default)) == 0:
            d = "(None)"
          else:
            d = str(self.Default)
          if self.consumes != 0:
            ret += lhspad + self.format_rhs(self.pad(" [ default:", 12) + d + " ]")
            ret += lhspad + self.format_rhs(self.pad(" [ data type:", 12) + self.DataType + " ]")
      else:
        ret += self.format_rhs(self.ShortHelp)
      if ReturnAsString:
        return ret
      sys.stdout.write(ret)
      sys.stdout.write("\n\n")
      sys.stdout.flush()
    



