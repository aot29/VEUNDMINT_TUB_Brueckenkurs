import subprocess
import sys

variants = ["std", "unotation"]



for vr in variants:
    print("-- GENERATING VARIANT " + vr + " --------------------------------------")
    p = subprocess.Popen(["python3", "tex2x.py", "VEUNDMINT", "variant=" + vr], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
    (output, err) = p.communicate()
    if (p.returncode > 1) or (p.returncode < 0):
        print("-- QUITTING VARIANT " + vr + " WITH ERROR " + str(p.returncode) + " -----------")
        sys.exit(1)
    else:
        if (p.returncode == 1):
            print("-- VARIANT " + vr + " OK WITH WARNINGS ------------------------------------")
        else:
            print("-- VARIANT " + vr + " STD OK ----------------------------------------------")
        
        fname = "variant_" + vr + ".zip"
        pz = subprocess.Popen(["zip", "-r", fname, "../tu9onlinekurstest/*"], stdout = subprocess.PIPE, shell = False, universal_newlines = True)
        (output, err) = pz.communicate()
        if pz.returncode != 0:
            print("-- ZIPPING OF VARIANT " + vr + " WITH ERROR " + str(pz.returncode) + " -----------")
            sys.exit(1)
        else:
            print("-- ZIPPING OF VARIANT " + vr + " COMPLETE: " + fname)
    
