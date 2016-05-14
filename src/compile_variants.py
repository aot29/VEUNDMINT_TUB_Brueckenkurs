import subprocess
import sys
import os
from git import Repo
import socket


variants = ["std", "unotation"]
wwwdirname = "onlinekursmathe" # relative to /var/www on mintlx3.scc.kit.edu
vtmp = "__vctmp" # directory to store the compiled tree for zipping, relative to src/.., will be removed afterwards
mdb = "develop_content" # mandatory branch for a release
pubserver = "mintlx3" # server for publication
wwwtarget = "/var/www" # directory to place folders for publishing

if (os.path.abspath(os.getcwd()) != os.path.abspath(os.path.dirname(__file__))):
    print("compile_variants must be called in its own directory, typically src in the converter tree")
    sys.exit(1)


h = repo.head
hc = h.commit

if socket.gethostname() != pubserver:
    print("Not on publication server " + pubserver + ", refusing to do anything!")
    sys.exit(1)

if repo.active_branch != mdb:
    print("Not on branch " + mdb + ", refusing to do anything!")
    sys.exit(1)

if repo.is_dirty():
    print("Local workspace for branch " + mdb + " is dirty, refusing to do anything!")
    sys.exit(1)
   

for vr in variants:
    print("-- GENERATING VARIANT " + vr + " --------------------------------------")
    p = subprocess.Popen(["python3", "tex2x.py", "VEUNDMINT", "cleanup=0", "variant=" + vr, "output=" + vtmp], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
    (output, err) = p.communicate()
    if (p.returncode > 1) or (p.returncode < 0):
        print("-- QUITTING VARIANT " + vr + " WITH ERROR " + str(p.returncode) + " -----------")
        sys.exit(1)
    else:
        if (p.returncode == 1):
            print("-- VARIANT " + vr + " OK WITH WARNINGS ------------------------------------")
        else:
            print("-- VARIANT " + vr + " STD OK ----------------------------------------------")

        os.chdir("..")
        os.chdir(vtmp)
        dname = wwwdirname
        if vr != "std":
            dname += "_" + vr
        fname = dname + ".tgz"
        pz = subprocess.Popen(["tar", "-c", "-v", "-z", "-f", os.path.join("..", fname), "."], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
        (output, err) = pz.communicate()
        if pz.returncode != 0:
            print("-- ZIPPING OF VARIANT " + vr + " WITH ERROR " + str(pz.returncode) + " -----------")
            sys.exit(1)
        else:
            print("-- ZIPPING OF VARIANT " + vr + " COMPLETE: " + fname)

        os.chdir("..")
        shutil.rmtree(vtmp)
        os.chdir("src")
        

    
