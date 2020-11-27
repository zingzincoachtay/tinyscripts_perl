#!/usr/bin/perl -w
use strict;
use warnings;
#http://aerostitch.github.io/programming/perl/oneliners/perl-dos2unix_mac2unix.html

### 1. dos2unix
###    Usefull command to convert a windows-formatted text file to the unix/linux format from the command-line. 
#.     It converts in-place ("-i" switch) the "\r\n" to "\n" characters using a regular expression.

perl -pi -e's/\015\012/\012/g' $ARGV[0]
