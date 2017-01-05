import subprocess
import re
from tex2x.Settings import ve_settings as settings
from tex2x.System import ve_system as sys
from tex2x.AbstractPreprocessor import AbstractPreprocessor

class ReleaseCheck(AbstractPreprocessor):
	
	def __init__(self, data):
		# copy interface member references
		self.data = data
	
	
	def preprocess( self ):
		fileList = self.getFileList()
		sys.message(sys.VERBOSEINFO, "Preprocessor working on " + str(len(fileList)) + " texfiles")
		nonpass = 0
		for texfile in fileList:
			tex = sys.readTextFile(texfile[0], settings.stdencoding)
			if not self.check(tex, texfile[1]):
				nonpass += 1
				sys.message(sys.VERBOSEINFO, "Original tex-file " + texfile[1] + " did not pass release check");
				if (settings.dorelease == 1):
					sys.message(sys.FATALERROR, "Refusing to continue with dorelease=1 after checkRelease failed, see logfile for details")
				
		sys.message(sys.CLIENTINFO, "Preparsing of " + str(len(fileList)) + " texfiles finished")
		sys.message(sys.CLIENTINFO, str(nonpass) + " files did not pass the release test, see logfile for details")
		sys.message(sys.CLIENTINFO, "A total of " + str(len(self.data['DirectHTML'])) + " DirectHTML blocks created")


	def check(self, tex, orgname):
		"""
		Checks if given tex code from file fname (original source!) is valid for a release version
		Return value: boolean True if release check passed
		"""
		reply = True
		
		# check desired tex file properties
		p = subprocess.Popen(["file", orgname], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
		(output, err) = p.communicate()

		fm = re.match(re.escape(orgname) + ": (LaTeX|TeX) document,(.*)", output, re.S)
		if fm:
			if "with very long lines" in fm.group(2):
				sys.message(sys.VERBOSEINFO, "tex file has very long lines, but ok for now")
			if "with CRLF line terminators" in fm.group(2):
				sys.message(sys.VERBOSEINFO, "tex file has windows-like CRLF line terminators, but ok for now")
		else:
			# does not prevent release, but should be mentioned, happens for example if texfile consists of input commands only
			sys.message(sys.VERBOSEINFO, "File " + orgname + " is not recognized as a TeX file by file command")
	
		# no Mtikzexternalize in a comment
		if re.search(r"\%([ \t]*)\\Mtikzexternalize", tex, re.S):
				sys.message(sys.CLIENTWARN, "Mtikzexternalize found in a comment")
				reply = False
	
		# no experimental environments
		if (re.search(r"\\begin\{MExperimental\}", tex, re.S)):
			sys.message(sys.VERBOSEINFO, "MExperimental found in tex file");
			reply = False
		if (re.search(r"\% TODO", tex, re.S)):
			sys.message(sys.VERBOSEINFO, "TODO comment found in tex file");
			reply = False
			
		# MSContent is no longer valid
		def scontent(m):
			nonlocal reply
			reply = False
			sys.message(sys.VERBOSEINFO, "MSContent found but no longer supported: " + m.group(1))
		re.sub(r"\\begin\{MSContent\}\{([^\}]*)\}\{([^\}]*)\}\{([^\}]*)\}(.*?)\\end\{MSContent\}", scontent, tex, 0, re.S)

		# each MXContent must have a unique content id
		def xcontent(m):
			nonlocal reply
			xm = re.search(r"\\MDeclareSiteUXID\{([^\}]*)\}", m.group(4), re.S)
			if not xm:
				reply = False
				sys.message(sys.VERBOSEINFO, "MXContent found without unique id declaration: " + m.group(1))
		re.sub(r"\\begin\{MXContent\}\{([^\}]*)\}\{([^\}]*)\}\{([^\}]*)\}(.*?)\\end\{MXContent\}", xcontent, tex, 0, re.S)
		
		return reply
