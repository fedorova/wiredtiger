#!/usr/bin/python -tt

import sys
import argparse
import re


def parse_file(fname, pattern):

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
    print('[0-9]+ '+ pattern);
    p_populate = re.compile('[0-9]+ '+ pattern);

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
    parser.add_argument("-p", "--pattern", type=str, nargs=1,
                        help="string following the performance number, as"
                        "in \"500 ops\". \"ops\" is the string we will search "
                        "for to extract performance numbers.");

    args = parser.parse_args();
    print("The files are: ");
    print args.files
    print("Pattern string is: "),
    print args.pattern;

    for fname in args.files:
        parse_file(fname, args.pattern[0]);

if __name__ == '__main__':
    main()
