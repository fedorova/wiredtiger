#!/usr/bin/python -tt

import sys
import argparse

def parse_file(fname):

    print "Parsing file " + fname;

    try:
        logFile = open(fname, "r");
    except:
        print "Could not open file " + fname;
        return;

    try:
        out_fname = fname + ".perfume"
        outputFile = open(out_fname, "w");
    except:
        print "Could not open file " + out_fname;
        return;

    for line in logFile:

        words = line.split(" ");
        thread = 0;
        time = 0;
        event = "";

        if(len(words) < 4):
            continue;

        if(words[0] == "*"):
            if(words[1].startswith("[")):
                # we have a format * [event name] thread time
                for i in range (1, len(words)-1):
                    event = event + words[i];
                    if(words[i].endswith("]")):
                        break;
                    else:
                        event = event + " ";

                try:
                    thread = int(words[i+1]);
                    time = long(words[i+2]);
                except (ValueError, IndexError):
                    print "Could not parse: " + line;
                    continue;

        elif(words[0] == "-->" or words[0] == "<--"):
            try:
                event = words[1];
                thread = int(words[2]);
                time = long(words[3]);
            except ValueError:
                print "Could not parse: " + line;
                continue;

        if(words[0] == "-->"):
            outputFile.write(str(thread) + ", " + event + " enter, "
                             + str(time) + "\n");
        elif(words[0] == "<--"):
            outputFile.write(str(thread) + ", " + event + " exit, "
                             + str(time) + "\n");
        elif(words[0] == "*"):
            outputFile.write(str(thread) + ", " + event + ", "
                             + str(time) + "\n");


def main():

    parser = argparse.ArgumentParser(description=
                                     'Process performance log files');
    parser.add_argument('files', type=str, nargs='+',
                        help='log files to process');

    args = parser.parse_args();
    print args.files;

    for fname in args.files:
        parse_file(fname);


if __name__ == '__main__':
    main()
