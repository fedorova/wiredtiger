#!/usr/bin/python -tt

import sys
import argparse
import re


def parse_file(fname):

    try:
        fd = open(fname, "r");
    except:
        print "Could not open file " + fname;
        return;

    # Regex for the number of threads
    p_threadstring = re.compile('-[0-9]+T');

    # Regex for extracting a number
    p_num = re.compile('[0-9]+');

    # Regex for the number of ops
    p_populate = re.compile('stat:[0-9]+');

    for line in fd:
        match = p_threadstring.search(line);

        if (match is not None):
            num_match = p_num.search(match.group());
            print(num_match.group() + '\t'),

        match = p_populate.search(line);
        if(match is not None):
            num_match = p_num.search(match.group());
            print(num_match.group());


def main():

    parser = argparse.ArgumentParser(description=
                                     'Process files containing the results of '
                                     'grepping for performance numbers on many '
                                     'test.stat file.');
    parser.add_argument('files', type=str, nargs='+',
                        help='grep output files to process');

    args = parser.parse_args();
    print args.files;

    for fname in args.files:
        parse_file(fname);

if __name__ == '__main__':
    main()
