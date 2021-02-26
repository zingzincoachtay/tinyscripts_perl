#!/usr/bin/perl

use HTTP::UserAgent;
my $q = HTTP::UserAgent->new;
my $rutracker = 'http://rutracker.org/forum/viewforum.php?f=1257';

my $k=0; my $s='';
open RT, '>rutlink.txt';
do {
  my $Page = $q->get( $rutracker.$s );
  $k+=50;
  $s = '&start='.$k;
  if( $Page->is_success ){
    print RT $Page->decode_content;
  }
}while( $k<=200 );

1;