import subprocess
import sys
import os
from git import Repo
import socket
import shutil
import getpass
import time


variants = ["std", "unotation"]
wwwdirname = "onlinekursmathe" # relative to /var/www on mintlx3.scc.kit.edu
vtmp = "__vctmp" # directory to store the compiled tree for zipping, relative to src/.., will be removed afterwards
mdb = "TU9Onlinekurs" # mandatory branch for a release
pubserver = "mintlx3" # server for publication
rifile = "release_info.txt" # will be updated

cdir = os.path.abspath(os.path.dirname(__file__))

if (os.path.abspath(os.getcwd()) != cdir):
    print("compile_variants must be called in its own directory, typically src in the converter tree")
    sys.exit(1)

repo = Repo("..")
assert not repo.bare
h = repo.head
hc = h.commit

if socket.gethostname() != pubserver:
    print("Not on publication server " + pubserver + " !!")
if repo.active_branch.name != mdb:
    print("Not on branch " + mdb + " !!")
if repo.is_dirty():
    print("Local workspace for branch " + mdb + " is dirty !!")


tagn = 2 # publish1 was done in branch develop_software
while ("AUTOPUBLISH" + str(tagn)) in repo.tags:
    tagn += 1
print("Next autopublish number will be " + str(tagn))
print("This program will automatically compile and release the current commit of branch " + mdb + ", ARE YOU SURE (type YES if your dare)?")
rp = input()
if rp != "YES":
    print("...aborting")
    sys.exit(1)

for vr in variants:
    print("-- GENERATING VARIANT " + vr)
    p = subprocess.Popen(["python3", "tex2x.py", "VEUNDMINT", "dotikz=1", "cleanup=0", "dopdf=1", "borkify=1", "variant=" + vr, "output=" + vtmp], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
    (output, err) = p.communicate()
    if (p.returncode > 1) or (p.returncode < 0):
        print("-- QUITTING VARIANT " + vr + " WITH ERROR " + str(p.returncode))
        sys.exit(1)
    else:
        if (p.returncode == 1):
            print("-- VARIANT " + vr + " OK WITH WARNINGS")
        else:
            print("-- VARIANT " + vr + " STD OK")

        os.chdir("..")
        os.chdir(vtmp)
        dname = wwwdirname
        if vr != "std":
            dname += "_" + vr
        fname = dname + ".tgz"
        pz = subprocess.Popen(["tar", "-c", "-v", "-z", "-f", os.path.join("..", fname), "."], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
        (output, err) = pz.communicate()
        if pz.returncode != 0:
            print("-- ZIPPING OF VARIANT " + vr + " WITH ERROR " + str(pz.returncode))
            sys.exit(1)
        else:
            print("-- ZIPPING OF VARIANT " + vr + " COMPLETE: " + fname)

        os.chdir("..")
        shutil.rmtree(vtmp)
        os.chdir("src")
        
# actual publishing of the files, requests user priviliges from user
for vr in variants:
    dname = wwwdirname
    if vr != "std":
        dname += "_" + vr
    fname = dname + ".tgz"

    td = os.path.join("/", "var", "www", dname)
    if not os.path.exists(td):
        print("Cannot access /var/www/" + dname + ", stopping process")
        sys.exit(1)
    os.chdir(td)
    p = subprocess.Popen(["tar", "-xvzf", os.path.join(cdir, "..", fname)], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
    (output, err) = p.communicate()
    if p.returncode != 0:
        print("-- QUITTING PUBLISHING OF VARIANT " + vr + " WITH ERROR " + str(p.returncode))
        sys.exit(1)
    else:
        pc = subprocess.Popen(["chmod", "-R", "777", "."], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
        (output, err) = pc.communicate()
        print("-- VARIANT " + vr + " PUBLISHED TO " + td)
        
# commit and push std variant to release history
dname = wwwdirname
fname = dname + ".tgz"
os.chdir(cdir)
os.chdir("..")
os.chdir("releases")


commsg = "AUTOPUBLISH" + str(tagn) + " using compile_variants.py on machine " + socket.gethostname() + " by user " + getpass.getuser()
hc = repo.head.commit
infomsg = commsg + "\n" \
        + "Timestamp: " + time.ctime(time.time()) + "\n" \
        + "Previous commit on branch " + mdb + " was this one:\n" \
        + "  branch: " + repo.active_branch.name + "\n" \
        + "  committer: " + hc.committer.name + "\n" \
        + "  message: " + hc.message.replace("\n", "") + "\n" \
        + "  hexsha: " + hc.hexsha + "\n\n"

with open(rifile, "a") as myfile:
    myfile.write(infomsg)

os.chdir(dname)
p = subprocess.Popen(["tar", "-xvzf", os.path.join(cdir, "..", fname)], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
(output, err) = p.communicate()
if p.returncode != 0:
    print("-- QUITTING PUBLISHING OF RELEASE HISTORY WITH ERROR " + str(p.returncode))
    sys.exit(1)
else:
    print("-- VARIANT std WRITTEN TO RELEASE DIRECTORY")

os.chdir("..")
repo.git.add("releases/" + rifile)
repo.git.add("releases/" + dname + "/")
repo.index.commit(commsg)
repo.create_tag("AUTOPUBLISH" + str(tagn))
print("-- VARIANT std COMMIT TO RELEASE GIT HISTORY, TAGNR = " + str(tagn))
print("PLEASE PUSH THE COMMIT RIGHT NOW!")
    
sys.exit(0)
 
    
