#!/usr/bin/env python3
import argparse, sys

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="")
    parser.add_argument("pos", type=str, nargs='?', const=1, default=False, help='Positional argument')
    parser.add_argument("-p", "--param", help='Param')
    parser.add_argument("-s", "--switch", dest='s', action='store_true', help='Switch')

    args = parser.parse_args()

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        exit(1)

    print(args)
