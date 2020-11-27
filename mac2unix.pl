#!/usr/bin/perl -w
use strict;
use warnings;
#http://aerostitch.github.io/programming/perl/oneliners/perl-dos2unix_mac2unix.html

### 2. mac2unix
###    Usefull command to convert a mac-formatted text file to the unix/linux format from the command-line. 
#      It converts in-place ("-i" switch) the "\r" that is the end of line character in mac to "\n" characters using perl built-in capabilities.

#perl -w015l12pi -e1 mac_formated_file.txt

which is equivalent to the following but adds a new line at the end:

perl -pi -e's/\015/\012/g' mac_formated_file.txt
