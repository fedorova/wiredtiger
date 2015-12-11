#!/usr/bin/python -tt

import sys
import argparse

#
# LogRecord contains all the fields we expect in the log record.

class LogRecord:

    def __init__(self, func, thread, time):
        self.func = func;
        self.thread = thread;
        self.time = long(time);

    def printLogRecord(self):
        print(func + " " + str(thread) + " " + str(time));

#
# LockRecord contains temporary information for generatinglock-held times

class LockRecord:

    def __init__(self, name, fname, thread, timeAcquired):
        self.name = name;
        self.funcName = fname;
        self.thread = thread;
        self.timeAcquired = long(timeAcquired);

    def printLockRecord(self):
        print(name + ": [" + str(thread) + "]" + str(timeAcquired));

#
# PerfData class contains informtation about the function running
# times. For now it is simple.

class PerfData:

    def __init__(self):
        self.numCalls = 0;
        self.totalRunningTime = long(0);

    def getAverage(self):
        return (float(self.totalRunningTime) / float(self.numCalls));

    def printSelf(self):
        print("\t Num calls: " + str(self.numCalls));
        print("\t Total running time: " + str(self.totalRunningTime) + " ns.");
        print("\t Average running time: "
              + str(long(self.getAverage())) + " ns.");

#
# LockData class contains information about lock-related functions

class LockData:

    def __init__(self):
        self.numAcquire = 0;
        self.numRelease = 0;
        self.numTryLock = 0;
        self.timeAcquire = 0;
        self.timeTryLock = 0;
        self.timeRelease = 0;
        self.timeHeld = 0;
        self.lastAcquireRecord = None;

    def getAverageAcquire(self):
        return (float(self.timeAcquire) / float(self.numAcquire));

    def getAverageRelease(self):
        return (float(self.timeRelease) / float(self.numRelease));

    def getAverageTryLock(self):
        return (float(self.timeTryLock) / float(self.numTryLock));

    def getAverageTimeHeld(self):
        return (float(self.timeHeld) / float(self.numRelease));

    def printSelf(self):
        print("\t Num acquire: " + str(self.numAcquire));
        print("\t Num trylock: " + str(self.numTryLock));
        print("\t Num release: " + str(self.numRelease));
        print("\t Average time in acquire: "
              + str(long(self.getAverageAcquire())) + "ns.");
        print("\t Average time in trylock: "
              + str(long(self.getAverageTryLock())) + "ns.");
        print("\t Average time in release: "
              + str(long(self.getAverageRelease())) + "ns.");
        print("\t Average time the lock was held: "
              + str(long(self.getAverageTimeHeld())) + "ns.");

#
# The following data structures and functions help us decide what
# kind of lock-related action the function is doing:
# acquiring the lock, releasing the lock, of trying to acquire the lock.
#

acquireStrings = ["acquire", "lock"];
trylockStrings = ["trylock"];
releaseStrings = ["release", "unlock"];

def looks_like_acquire(funcname):

    if(looks_like_release(funcname)):
        return False;
    if(looks_like_trylock(funcname)):
        return False;

    for hint in acquireStrings:
        if(funcname.find(hint) != -1):
            return True;
    return False;

def looks_like_trylock(funcname):

    for hint in trylockStrings:
        if(funcname.find(hint) != -1):
            return True;
    return False;


def looks_like_release(funcname):

    for hint in releaseStrings:
        if(funcname.find(hint) != -1):
            return True;
    return False;

def looks_like_lock(funcname):

    if(looks_like_acquire(funcname) or
       looks_like_release(funcname) or
       looks_like_trylock(funcname)):
        return True;
    else:
        return False;

#
# These functions process lock-related functions. One of its
# goals is to match lock releases to lock acquisitions and
# compute the time spent holding the lock. Another goal is to
# simply compute the amount of time spent in each lock-related
# action (acquire, release, trylock).
#
# All stats are organized by lock name and kept in the perFileLocks
# dictionary

perFileLocks = {}


def do_lock_processing(locksDictionary, logRec, runningTime,
                       nameWords):

    lockName = "";

    # Reconstruct the lock name
    for(word in nameWords):
        lockName = lockName + word + " ";

    print("Lock name: " + lockName);

    if(lockName not locksDictionary.has_key(lockName)):
        lockData = LockData();
        locksDictionary[lockName] = lockData;

    lockData = locksDictionary[lockName];

    # If this is an acquire or trylock, simply update the stats in the
    # lockData object and push it on the lock stack.
    #
    # If this is a release, update the stats in the lockData object and
    # find the corresponding acquire or trylock in the lockStack, so
    # we can compute the lock held time.
    #
    if(looks_like_acquire(func) or looks_like_trylock(func)):

        lockRec = LockRecord(lockName, func, logRec.thread, logRec.time);

        lastAcquireRecord = lockData.lastAcquireRecord;

        if(looks_like_acquire(func)):
            if(lastAcquireRecord not None):
                print("That's weird. Another acquire record seen on acquire.");
                print("Current lock record:");
                lockRec.printLockRecord();
                print("Existing acquire record:");
                lastAcquireRecord.printLockRecord();
            else:
                lockData.lastAcquireRecord = lockRec;

            lockData.numAcquire = lockData.numAcquire + 1;
            lockData.timeAcquire = lockData.timeAcquire + runningTime;
        else:
            if(lastAcquireRecord not None):
                if(lastAcquireRecord.funcName != func):
                    print("That's weird. Another lock acquire record seen, "
                          "but that's not us.");
                    print("Current lock record:");
                    lockRec.printLockRecord();
                    print("Existing acquire record:");
                    lastAcquireRecord.printLockRecord();
                else:
                    # If there is already an acquire record with the same func
                    # name as ours, this means that the lock was not acquired in
                    # the last try attempt. We update the timestamp, so that
                    # lock held time is subsequently calculated correctly.
                    lastAcquireRecord.timeAcquired = logRec.time;
            else:
                lockData.lastAcquireRecord = lockRec;

            lockData.numTryLock = lockData.numTryLock + 1;
            lockData.timeTryLock = lockData.timeTryLock + runningTime;

    else if(looks_like_release(func)):

        if(lastAcquireRecord is None):
            print("Could not find a matching acquire for: ")
            logRec.printLogRecord();
        else:
            lockHeldTime = logRec.time - lastAcquireRecord.timeAcquired;
            print("Lock " + lockName + " was held for "
                  + str(lockHeldTime) + "ns");
            lockData.timeHeld = lockData.timeHeld + lockHeldTime;

        lockData.numRelease = lockData.numRelease + 1;
        lockData.timeRelease = lockData.timeRelease + runningTime;

#
# A per-file dictionary of functions that we encounter in the log file.
# Each function will have a corresponding list of PerfData objects,
# one for each file it parses.

perFile = {}


def parse_file(fname):

    stack = [];
    lockStack = [];

    print "Parsing file " + fname;

    try:
        logFile = open(fname, "r");
    except:
        print "Could not open file " + fname;
        return;

    perFile[fname] = {}
    perFileLocks[fname] = {}

    for line in logFile:

        words = line.split(" ");
        thread = 0;
        time = 0;
        func = "";

        if(len(words) < 4):
           continue;

        try:
            func = words[1];
            thread = int(words[2]);
            time = long(words[3]);
            rec = LogRecord(func, thread, time)
        except ValueError:
            print "Could not parse: " + line;
            continue;

        if(words[0] == "-->"):
            # Timestamp for function entrance
            # Push each entry record onto the stack.
            stack.append(rec);

        elif(words[0] == "<--"):
            found = False;

            # Timestamp for function exit. Find its
            # corresponding entry record by searching
            # the stack.
            while(len(stack) > 0):
                stackRec = stack.pop();
                if(stackRec is None):
                    print("Ran out of opening timestamps when searching "
                          "for a match for: " + line);
                    break;

                # If the name of the entrance record
                # on the stack is not the same as the name
                # in the exit record we have on hand, complain
                # and continue. This means that there are errors
                # in the instrumentation, but we don't want to fail
                # because of them.
                if(not (stackRec.func == rec.func)):
                    continue;
                else:
                    # We have a proper function record. Let's add the data to
                    # the file's dictionary for this function.

                    runningTime = long(rec.time) - long(stackRec.time);
                    thisFileDict = perFile[fname];

                    if(not thisFileDict.has_key(stackRec.func)):
                        newPDR = PerfData();
                        thisFileDict[stackRec.func] = newPDR;

                    pdr = thisFileDict[stackRec.func];
                    pdr.totalRunningTime = pdr.totalRunningTime + runningTime;
                    pdr.numCalls = pdr.numCalls + 1;
                    found = True

                    # If this is a lock-related function, do lock-related
                    # processing
                    if(len(words) > 4 and looks_like_lock(func)):
                        do_lock_processing(perFileLocks[fname], lockStack, rec,
                                           runningTime,
                                           words[4:len(words)]);

                    break;
            if(not found):
                print("Could not find matching function entrance for line: \n"
                      + line);

    print("\n");


def main():

    parser = argparse.ArgumentParser(description=
                                     'Process performance log files');
    parser.add_argument('files', type=str, nargs='+',
                        help='log files to process');

    args = parser.parse_args();
    print args.files;

    for fname in args.files:
        parse_file(fname);

    # Let's print the data!
    for key, perFileDict in perFile.iteritems():
        print(" SUMMARY FOR FILE " + key + ":");
        print("------------------------------");

        for fkey, pdr in perFileDict.iteritems():
            print(fkey + ":");
            pdr.printSelf();

        print("------------------------------");

if __name__ == '__main__':
    main()
