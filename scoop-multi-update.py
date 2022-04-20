import threading
import os
import subprocess
import sys

def do_updates():
    lock = threading.Lock()
    threads = []
    for arg in sys.argv[1:]:
        threads.append(start_scoop_update_for(arg, lock))
    for thread in threads:
        thread.join()

def start_scoop_update_for(pkg, lock):
    result = threading.Thread(target=scoop_update, args=(pkg, lock))
    result.start()
    return result

def scoop_update(pkg, lock):
    with lock:
        print("start update: %s" % pkg)
    child_process = subprocess.run("scoop update %s" % pkg, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    exit_code = child_process.returncode
    with lock:
        if exit_code == 0:
            print("update complete: %s" % pkg)
        else:
            print("update failed: %s" % pkg)
            print("stderr: %s" % child_process.stderr)

if __name__ == "__main__":
    do_updates()