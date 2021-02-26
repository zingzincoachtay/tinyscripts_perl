#!/usr/bin/perl -w
use strict;
sub md5sum2hash {
  my ($f) = @_;
  my $sum = {};
  open(my $fh,'<:encoding(UTF-8)',$f)
    or die "Could not open file '$f' $!";
  while(my $r = <$fh>){
    chomp $r;
    my ($md5,$path) = ($r=~/^(\S+)\s+(.+)$/);
    if( !exists $sum->{$md5} ){ $sum->{$md5} = $path;}
    else{ print "Error '$md5' found multiple times.\n";}
  }
  return $sum;
}
sub duplicates {
  my ($dup,$keep) = @_;
  while(my($k,$v)=each(%$dup)){
    my ($rm) = ($v=~/^.+\/([^\/]+)$/);
    if(exists $keep->{$k}){
      my $u = $keep->{$k};
      my ($echo) = ($u=~/^.+\/([^\/]+)$/);
      if( $rm eq $echo ){
        print "rm \"$v\"\n";
        print "echo Keep: \"$u\"\n\n";
      } else {
        print "echo rm \"$v\"\n";
        print "echo mv --backup=numbered \"$u\" \"$u\"\n\n";
      }
    }
  }
}
my @md5f = @ARGV[0 .. 1];
my $removefromthese = md5sum2hash($md5f[0]);
print scalar(keys %$removefromthese)."\n";
my $keepthose = md5sum2hash($md5f[1]);
print scalar(keys %$keepthose)."\n";
duplicates($removefromthese,$keepthose);

