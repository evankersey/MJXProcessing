#dont use me

import os  # interface with path
import fnmatch  # compare substring filename

# get par or rec file, returns file

defaultPath = "/mnt/Filbey/common/Studies/MJX_WF/examples/NL"


def findParOrRec(path):
    rawDataList = []
    for roots, dirs, files in os.walk(path):
        for file in files:
            if fnmatch.fnmatch(file, "*.REC"):
                # print(file)
                rawDataList.append(file)
            if fnmatch.fnmatch(file, "*.PAR"):
                # print(file)
                rawDataList.append(file)
    return rawDataList


def findT1(path=defaultPath):
    fileNameList = []
    for file in findParOrRec(path):
        if fnmatch.fnmatch(file, "*T1*"):
            fileNameList.append(file)
    return fileNameList


def findDwi(path=defaultPath):
    dwiList = []
    for file in findParOrRec(path):
        if fnmatch.fnmatch(file, "*dwi*"):
            dwiList.append(file)
    return dwiList


def findFmap(path=defaultPath):
    fmapList = []
    for file in findParOrRec(path):
        if fnmatch.fnmatch(file, "*topup*"):
            fmapList.append(file)
    return fmapList


def findTask(path=defaultPath):
    taskList = []
    for file in findParOrRec(path):
        if fnmatch.fnmatch(file, "*bold*"):
            if not fnmatch.fnmatch(file, "*topup*"):
                taskList.append(file)
    return taskList



print(findT1())
print(findDwi())
print(findFmap())
print(findTask())
