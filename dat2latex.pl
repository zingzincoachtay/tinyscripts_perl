#!/usr/bin/perl -w

# USAGE
# - use like: "dat2latex.pl my-data.gp.dat > my-table.tex 2> progress.log"
# - copy-and-paste result into TeX source OR
#   include in a TeX file via "\input{my-table.tex}" OR
#   run "reLyX -c article -p my-table.tex" on it to get it into LyX

# OBJECTIVE
# - tries to convert gnuplot data tables into valid (!) (La?)TeX tables

# copyright: GPL

# AUTHORS
# - KH   Karsten Hilbert <Karsten.Hilbert@gxm.net>
# - FAM  Frank Meineke <frank@imise.uni-leipzig.de>

# NOTE
# This script was formerly called gp2tex.pl, but renamed to dat2latex.pl when
# copied to gnuplot web site -- the script is more generally useful than just
# for gnuplot files.

# FEATURES

# data
# - handles multiple data blocks (indexes)
# - data blocks may have different number of columns
# - autodetects number of data columns

# column titles
# - can be supplied
# - format: "#titles%title 1%title 2%title 3"
# - valid content: any single line TeX construct
# - default: numbered titles
# - scope: until next change of data block width
# - cave: if you supply titles there _must_ be one for each column
#         or default titles will be used
# - cave: if data block width changes and matching titles have
#         not been supplied it will go back to default titles
# - I wonder why gnuplot doesn't do this, too, but, oh well.

# captions
# - can be supplied
# - format: "#caption%text for the caption"
# - default: most recent non-empty comment
# - valid content: any single line TeX construct
# - scope: one data block (table)

# cell layout
# - can be supplied
# - format: "#layout%a layout"
# - valid content: any valid TeX layout
# - default: all cells aligned left
# - scope: until number of data columns changes
# - cave: once you supply a layout it better be valid
# - cave: if you supplied any layout you will have to resupply a
#         new matching layout if the number of data columns changes
#
# - This is YOUR chance ! Make it smarter:
#   - check validity of supplied layouts
#   - revert back to default layout if invalid

# table reference labels
# - can be supplied
# - format: "#label%a label"
# - valid content: any valid TeX label
# - default: (commented out) smart default labels
# - scope: one data block
# - cave: if you supply more than one label make sure they are all unique

# general
# - diagnostic messages are printed on STDERR
# - if STDOUT and STDERR are the same pipe the result is still valid TeX
# - turns gnuplot comments into TeX comments
# - keeps a reference to the source file and conversion script

# LIMITATIONS
# - long tables must be splitted by hand to fit on the page
# - a supplied layout _must_ be valid or TeX won't like the result
# - if you supplied any layout you will have to resupply a
#   new matching layout if the number of data columns changes

# HISTORY
# - KH  20000328 first release
# - FAM 20000329 two small patches/changes
# - KH  20000329 fixed stupid bug that broke "smart captions" easily
# - KH  20000420 tidied up comments and code

#-------------
# includes
#-------------
use IO::Handle;

#-------------
# subroutines
#-------------
sub start_table;
sub end_table;

#-------------
# init
#-------------
STDERR->autoflush(1);	# let STDOUT and STDERR messages appear in the correct
STDOUT->autoflush(1);	# temporal order if both are piped to the same target,
                        # this may make things somewhat slower, though
$blank_cnt=0;		# how many blank lines have currently occurred in a row
$block_idx=0;
$nr_of_cols=0;
$first_line_cols=0;	# scope: one data block
$table_finished=0;	# don't write table closing TeX statements more than once
$titles_found=0;
$nr_of_titles=0;
$tag="";
$caption="";		# scope: one data block
$caption_found=0;
$layout="";		# scope: until block width changes
$layout_found=0;
$reflabel="";		# scope: one data block
$reflabel_found=0;

#-------------
# work
#-------------
print STDERR "% $0: Starting.\n\n";

print "% creator: $0\n";
print "% - include into TeX file with: \"\\input{my-table-file.tex}\"\n";
print "% - convert to LyX with: \"reLyX -c article -p my-table-file.tex\"\n\n";

$srcname=$ARGV[0];
print "% Source file = $srcname\n";
open(SRC,$srcname) || die "% $0: Can't open $srcname.\n";
print "\n";

SRCLINE: while (<SRC>) {
    chomp;
    $line = $_;

    # catch column title definitions
    if ($line =~ /^(\s)*#titles/) {
	print STDERR "% $0: Found column titles. :-)\n";
	$titles_found = 1;
	($tag,@titles) = split (/%/,$line);
	$nr_of_titles = scalar @titles;
	next SRCLINE;
    }

    # catch table caption definitions
    if ($line =~ /^(\s)*#caption/) {
	print STDERR "% $0: Found caption. :-)\n";
	$caption_found = 1;
	($tag,$caption) = split (/%/,$line);
	next SRCLINE;
    }

    # catch cell layout
    if ($line =~ /^(\s)*#layout/) {
	print STDERR "% $0: Found column layout definition. :-)\n";
	($tag,$layout) = split (/%/,$line);
	$layout_found=1;
	next SRCLINE;
    }

    # catch reference label definitions
    if ($line =~ /^(\s)*#label/) {
	print STDERR "% $0: Found table reference label. :-)\n";
	($tag,$reflabel) = split (/%/,$line);
	$reflabel_found=1;
	next SRCLINE;
    }

    # catch normal comment lines
    # caveat:
    # - if you use "smart captions" make sure your comments do not contain any "%" signs
    # - however, all the "smart comments" supplying titles, labels and layouts will not affect smart captions
    # - in general any comment not being a valid TeX construct being used as a caption will probably bomb out
    # - someone really cool could filter out all the TeX special characters here ...
    # - at the moment there's only very dumb filtering that drops comment lines that _seem_ invalid
    if ($line =~ /^(\s)*#/) {
	print "% $line\n";
	print STDERR "% $0: Found comment.\n";
# Keine "Smart Captions" FAM 20000329
# Reenabled "Smart Captions" KH 20000329
	if ($caption_found == 0) {
	    # if non-empty comment only
	    if ($line !~ /^(\s)*#(\s)*$/) {
		# check for TeX special characters in $_
		# this works 'cause $line == $_ here
		SWITCH: {
		    /\$/ && do {
			last SWITCH;
		    };
		    /\&/ && do {
			last SWITCH;
		    };
		    /\%/ && do {
			last SWITCH;
		    };
		    /\_/ && do {
			last SWITCH;
		    };
		    /\{/ && do {
			last SWITCH;
		    };
		    /\}/ && do {
			last SWITCH;
		    };
		    /\~/ && do {
			last SWITCH;
		    };
		    /\^/ && do {
			last SWITCH;
		    };
		    /\"/ && do {
			last SWITCH;
		    };
		    /\\/ && do {
			last SWITCH;
		    };
		    /\|/ && do {
			last SWITCH;
		    };
		    /\</ && do {
			last SWITCH;
		    };
		    /\>/ && do {
			last SWITCH;
		    };
		    print STDERR "% $0: Keeping it as a possible caption.\n";
		    $caption = $line;
		}
	    }
	    # TeX doesn't like the "#" comment sign in front so remove it
	    $caption =~ tr/#/ /;
	}
	next SRCLINE;
    }

    # blank lines
    if ($line =~ /^[:blank:]*$/) {
	print STDERR "% $0: Encountered blank line.\n";
	print STDERR "% $0: Could be part of an index separator. Taking note.\n";
	if ($block_idx == 0) {
	    print STDERR "% $0: First data block not found yet. Ignoring.\n";
	} else {
	    $blank_cnt++;
	    if ($blank_cnt > 1) {
		print STDERR "% $0: $blank_cnt blank lines in a row !\n";
		if ($blank_cnt == 2) {
		    print STDERR "% $0: This definitely starts a new data block.\n";
		    &end_table;
		    print "\n";
		}
	    }
	}
	next SRCLINE;
    }

    # every other line
# Trennen auch zwischen Blanks FAM 20000329
#    @fields = split (/\t/,$line);
    @fields = split (/[\t ]/,$line);
    $nr_of_cols = scalar @fields;

    if ($block_idx == 0) {
	print STDERR "% $0: Found start of first data block.\n";
	$first_line_cols = $nr_of_cols;
	print STDERR "% $0: First line has $first_line_cols data columns.\n";
	$block_idx++;
	&start_table;
    } else {
	if ($blank_cnt > 0) {
	    $block_idx++;
	    print STDERR "% $0: Found start of data block #$block_idx.\n";
	    $first_line_cols = $nr_of_cols;
	    print STDERR "% $0: First line has $first_line_cols data columns.\n";
	    &start_table;
	}
    }
    $blank_cnt = 0;

    if ($first_line_cols != $nr_of_cols) {
	print STDERR "% $0: WARNING !\n";
	print STDERR "% Number of columns in data block is not constant.\n";
	print STDERR "% $0: First line of block had $first_line_cols columns.\n";
	print STDERR "% $0: Current line of block has $nr_of_cols columns.\n";
	print STDERR "% $0: Line in $srcname: #$.\n";
	print STDERR "% $0: Table in output: #$block_idx\n";
    }
    
    print "  ";
    print join (' & ',@fields);
    print "\\\\\n";
}

if ($block_idx > 0) {
    &end_table;
}

print STDERR "% $0: Done.\n";

#--------------------------------------------------------------
sub start_table {
    print "\\begin{table}\n";
    print " \\caption{$caption}\n";

    # write table reference label
    if ($reflabel_found == 1) {
	# supplied
	print " \\label{$reflabel}\n";
    } else {
	# default
	print " %\\label{dat2latex-$block_idx}\n";
    }

    print " \\begin{center}\n";

    # write table format
    if ($layout_found == 0) {
	# default
	print " \\begin{tabular}{|";
	for ($col_nr = 1; $col_nr < ($nr_of_cols + 1); $col_nr++) {
	    print "l|";
	}
    } else {
	# supplied
	print " \\begin{tabular}{";
	print "$layout";
    }
    print "} % modify table format to your needs\n";

    # write column titles
    print "  \\hline %-------------------------------------------\n";

    if ($titles_found == 1) {
	if ($first_line_cols != $nr_of_titles) {
	    print STDERR "% $0: WARNING !";
	    print STDERR "% $0: The number of column titles found does not match\n";
	    print STDERR "% $0: the number of columns in this datablock. I will go\n";
	    print STDERR "% $0: back to default column titles because otherwise\n";
	    print STDERR "% $0: TeX will complain and refuse to compile this table.\n";
	    print "  title 1";
	    for ($col_nr = 2; $col_nr < ($nr_of_cols + 1); $col_nr++) {
		print " & title $col_nr";
	    }
	} else {
	    print "  ";
	    print join (' & ',@titles);
	}
    } else {
	print "  title 1";
	for ($col_nr = 2; $col_nr < ($nr_of_cols + 1); $col_nr++) {
	    print " & title $col_nr";
	}
    }
    print "\\\\\n";

    print "  \\hline %-------------------------------------------\n";
    print "  \\hline %-------------------------------------------\n";
    
    $table_finished = 0;
}

sub end_table {
    if ($table_finished == 0) {
	print STDERR "% $0: OK. Let's finish up the previous table.\n";
	print "  \\hline %-------------------------------------------\n";
	print " \\end{tabular}\n";
	print " \\end{center}\n";
	print "\\end{table}\n";
	$table_finished = 1;
	# these have the scope of one table, so we want
	# to reset them as soon as we close a table
	$caption_found = 0;
	$reflabel_found = 0;
    }
}
