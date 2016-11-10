import os, subprocess, logging, re
import sys
from tex2x.Settings import Settings
from tex2x.Settings import ve_settings as settings

logger = logging.getLogger(__name__)

class TTMParser(object):
    """
    Class that can parse texfiles to xml. Relies on the 'ttm' binary.
    """

    def __init__(self, sys=None):
        self.subprocess = None
        self.settings = settings
        self.sys = sys

    def parse(self, tex_start=settings.sourceTEXStartFile, ttm_outfile=settings.ttmFile, tex_dir=settings.sourceTEX, ttm_bin=settings.ttmBin):
        """
        Parses files from TeX to ?, uses the converterDir Option which is set to /src
        """
        # TODO DH: Why exactly do we need this?
        self.sys.pushdir()

        if not os.path.exists(tex_dir):
            os.makedirs(tex_dir)

        os.chdir(tex_dir)

        try:
            with open(ttm_outfile, "wb") as outfile, open(tex_start, "rb") as infile:
                self.subprocess = subprocess.Popen([ttm_bin, '-p', tex_dir], stdout = outfile, stdin = infile, stderr = subprocess.PIPE, shell = True, universal_newlines = True)
                #output, err = self.subprocess.communicate()

            self._logResults(self.subprocess, ttm_bin, tex_start)
            #return output, err

        except BaseException as e:
            self.sys.popdir()
            import sys as real_sys
            self.sys.message(self.sys.FATALERROR, str(e))

        self.sys.popdir()

        # TODO what shall be returned here? A string to the output tex file? the content from the parsing process?

    def getParserProcess(self):
        """
        Return a reference to the ttmParser Process, might return None, when called
        before the parse function was called..
        """
        return self.subprocess

    def getParserSys(self):
        return self.sys

    def _logResults(self, ttm_process, ttm_bin, tex_start):
        """
        Log the output from ttm_process in a human readable form. Is still using the system class. It
        might be good to use logging.Logger instead(?)
        """
        if self.sys is not None and ttm_process is not None:

            (output, err) = ttm_process.communicate()

            if ttm_process.returncode < 0:
                self.sys.message(self.sys.FATALERROR, "Call to " + ttm_bin + " for file " + tex_start + " was terminated by a signal (POSIX return code " + ttm_process.returncode + ")")
            else:
                if ttm_process.returncode > 0:
                    self.sys.message(self.sys.CLIENTERROR, ttm_bin + " reported an error in file " + tex_start + ", error lines have been written to logfile")
                    s = output[-512:]
                    s = s.replace("\n",", ")
                    self.sys.message(self.sys.VERBOSEINFO, "Last lines: " + s)
                else:
                    self.sys.timestamp(ttm_bin + " finished successfully")

            # process output of ttm
            anl = 0 # abnormal newlines found by ttm
            cm = 0 # unknown latex commands
            ttmlines = err.split("\n")
            for i in range(len(ttmlines)):
                logger.debug("(ttm) %s" % ttmlines[i])
                self.sys.message(self.sys.VERBOSEINFO, "(ttm) " + ttmlines[i])
                m = re.search(r"\*\*\*\* Unknown command (.+?), ", ttmlines[i])
                if m:
                    self.sys.message(self.sys.CLIENTWARN, "ttm does not know LaTeX command " + m.group(1))
                    cm += 1
                else:
                    if "Abnormal NL, removespace" in ttmlines[i]:
                        anl += 1
                    else:
                        if "Error: Fatal" in ttmlines[i]:
                            self.sys.message(self.sys.FATALERROR, "ttm exit with fatal error: " + ttmlines[i] + ", aborting")


            if anl > 0:
                self.sys.message(self.sys.CLIENTINFO, "ttm found " + str(anl) + " abnormal newlines")

            if (cm > 0) and (settings.dorelease == 1):
                self.sys.message(self.sys.FATALERROR, "ttm found " + str(cm) + " unknown commands, refusing to continue on release version")