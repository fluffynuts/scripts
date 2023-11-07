import os
from os import path

if os.name == "nt":
    baseDir = "C:\\code"
else:
    baseDir = "%s/%s" % (os.path.expanduser("~"), "code")

opensource_projects = [
    "PeanutButter",
    "NExpect",
    "Quackers",
    "zarro",
    "dotnet-utils",
    "CorsairBatteryTrayIcon",
    "trash",
    "ahk",
    "scripts",
    "tampermonkey-scripts"
]

work_projects = [
    ("yumbi-web", "yumbi"),
    "codeo.core",
    "clyral.rabbitbus",
    ("yumbi-rtapi", "rtapi"),
    ("yumbi-dashboard", "dashboard"),
    ("yumbi-web-client", "phoenix"),
    "update-password",
    "codeo.cqrs",
    "reportio",
    "iraas",
    "yumbi-busd",
    ("yumbi-vouchers", "vouchers")
]


def clone(remote, local=None):
    if local is None:
        local = remote
    if path.exists(local):
        print("%s already in %s" % (local, os.getcwd()))
        return
    os.system("gh repo clone %s %s" % (remote, local))
    if path.exists("package.json"):
        chdir(local)
        os.system("npm i")
        chdir("..")


def chdir(where):
    print("Change dir: %s" % where)
    os.chdir(where)

start_dir = os.getcwd()
chdir(baseDir)
chdir("codeo")
for project in work_projects:
    if isinstance(project, tuple):
        remote = project[0]
        local = project[1]
    else:
        remote = project
        local = project
    repo = "codeo-za/%s" % remote
    clone(repo, local)
    clone(repo, "%s.alt" % local)

chdir("..")

chdir("opensource")
for project in opensource_projects:
    clone(project)

chdir(start_dir)
