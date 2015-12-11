#!/usr/bin/python -tt

import sys
import argparse


#
# LogRecord contains all the fields we expect in the log record.

class LogRecord:

    def __init__(self, func, thread, time, arg):
        self.func = func;
        self.thread = thread;
        self.time = long(time);
        self.arg = long(arg);

    def printLogRecord(self):
        print(func + " " + str(thread) + " " + str(time) + hex(arg));

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
# A per-file dictionary of functions that we encounter in the log file.
# Each function will have a corresponding list of PerfData objects,
# one for each file it parses.

perFile = {}

def parse_file(fname):

    stack = [];

    print "Parsing file " + fname;

    try:
        logFile = open(fname, "r");
    except:
        print "Could not open file " + fname;
        return;

    perFile[fname] = {}

    for line in logFile:

        words = line.split(" ");
        thread = 0;
        time = 0;

        if(len(words) < 5):
           continue;

        try:
            thread = int(words[2]);
            time = long(words[4]);
            func = words[1];
            arg = words[3]
            rec = LogRecord(func, thread, time, arg)
        except ValueError:
            print "Could not parse: " + line;
            continue;

        if(words[0] == "-->"):
            # Timestamp for function entrance
            # Push each entry record onto the stack.

            stack.append(rec);
        elif(words[0] == "<--"):
            # Timestamp for function exit. Find its
            # corresponding entry record by searching
            # the stack.

            while(True):
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
                    #print(stackRec.func + " did not encounter a matching"
                    #      "closing timestamp. Instead saw " + rec.func);
                    continue;
                else:
                    # We have a proper function record. Let's add the data to the
                    # file's dictionary for this function. 

                    runningTime = long(rec.time) - long(stackRec.time);
                    thisFileDict = perFile[fname];

                    if(not thisFileDict.has_key(stackRec.func)):
                        newPDR = PerfData();
                        thisFileDict[stackRec.func] = newPDR;
                        
                    pdr = thisFileDict[stackRec.func];
                    pdr.totalRunningTime = pdr.totalRunningTime + runningTime;
                    pdr.numCalls = pdr.numCalls + 1;
                    
                    break;


    print("\n");
    

def main():

    parser = argparse.ArgumentParser(description='Process performance log files');
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
