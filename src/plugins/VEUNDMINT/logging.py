"""    
    VEUNDMINT Logging module
    Copyright (C) 2016  VE&MINT-Projekt - http://www.ve-und-mint.de

    The VEUNDMINT Logging module is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or (at your
    option) any later version.

    The VEUNDMINT Logging module is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with the VEUNDMINT plugin package. If not, see http://www.gnu.org/licenses/.
"""

import time
import sys

class Logging(object):
    """
    Exposes logging functionality for the VEUNDMINT plugin package, especially logMessage and logTimestamp
    """
    
    
    # message type constants (strings!) which should be consistent with constants in the JS framework in dlog.js
    CLIENTINFO = "1"    # JS-Client: Sent as feedback to the server as an information, Converter: Displayed both on console and in logfile
    CLIENTERROR = "2"   # JS-Client: Sent as feedback tot the server as an error message, will be sent also if user has disabled USAGE, Converter: Colored error message on the console and in logfile
    CLIENTWARN = "3"    # JS-Client: Sent as feedback tot the server as a warning message, Converter: Colored warning message on the console and in logfile
    DEBUGINFO = "4"     # JS-Client: Will be displayed on the JS console if not on a release version, Converter: will be put to logfile
    VERBOSEINFO = "5"   # JS-Client: Like DEBUGINFO but only if doverbose is active (will always appear in logfile though)
    CLIENTONLY = "6"    # JS-Client: Will ALWAYS be displayed on the browser console, including release versions, without prefix (should be user friendly)
    FATALERROR = "7"    # Converter: Conversion chain is aborted giving the error message

    # bash console color scheme
    BASHCOLORRED = "\033[91m"
    BASHCOLORGREEN = "\033[92m"
    BASHCOLORRESET = "\033[0m"
  

    
    def __init__(self, logFilename, doVerbose, doColors):
        self.logFilename = logFilename
        self.doColors = doColors
        self.doVerbose = doVerbose
        
        self.startTime = time.time()
        self.checkTime = self.startTime

        with open(self.logFilename, 'w', encoding='utf-8') as log:
            log.write("Started logging at absolute time " + str(self.startTime) + " [seconds]\n")

    def _printMessage(self, color, txt):
        # green verbose messages only in logfile, and on console if verbose is active
        if ((color != self.BASHCOLORGREEN) or (self.doVerbose == 1)):
            if (self.doColors == 1):
                print(color + txt + self.BASHCOLORRESET)
            else:
                print(txt)
       
            
        with open(self.logFilename, 'a', encoding='utf-8') as log:
            log.write(txt + "\n")
            
            
    def message(self, lvl, msg):
        # Conversion is on a "server", not a client, server relevant information is displayed always
        if (lvl == self.CLIENTINFO):
            self._printMessage("", "INFO:    " + msg)
        else: 
            if (lvl == self.CLIENTERROR):
                self._printMessage(self.BASHCOLORRED, "ERROR:   " + msg)
            else:
                if (lvl == self.CLIENTWARN):
                    self._printMessage(self.BASHCOLORRED, "WARNING: " + msg)
                else:
                    if (lvl == self.DEBUGINFO):
                        self._printMessage(self.BASHCOLORGREEN, "DEBUG:   " + msg)
                    else:
                        if (lvl == self.VERBOSEINFO):
                            self._printMessage(self.BASHCOLORGREEN, "VERBOSE: " + msg)
                        else:
                            if (lvl == self.CLIENTONLY):
                                self._printMessage(self.BASHCOLORRED, "ERROR: Wrong error type " + lvl + " on conversion platform, message: " + msg)
                            else:
                                if (lvl == self.FATALERROR):
                                    self._printMessage(self.BASHCOLORRED, "FATAL ERROR: " + msg)
                                    print("Program aborted with error code 1")
                                    sys.exit(1)
                                else:
                                    self._printMessage(self.BASHCOLORRED, "ERROR: Wrong error type " + lvl + ", message: " + msg)
            

    
    def timestamp(self, msg):
        myTime = time.time()
        reltimediff = myTime - self.checkTime
        abstimediff = myTime - self.startTime
        self.checkTime = myTime
        self.message(self.VERBOSEINFO, msg + " (relative time: " + str(reltimediff) + ", absolute time: " + str(abstimediff) + " [seconds])")

