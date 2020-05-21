#!/usr/bin/perl -w
use strict;
require "ldperl.pl";

if( check_argc_exit($#ARGV) ){
  print "Only exactly two folders must be given to the arguments.\n" && exit;
} else {}

switch_methods(@ARGV);

sub check_argc_exit {
  return ($#ARGV<1 || $#ARGV>1) ? 1 : 0;
}
sub switch_methods {
  my ($target_object,$likely_destination) = @_;
  if(-f $target_object && -f $likely_destination){
    print 'Recommend using `diff -q "'.$target_object.'" "'.$likely_destination.'"`'."\n" && exit;
  }
  if(-d $target_object && -f $likely_destination){
    print 'Redo execution  `perl $0 "'.$likely_destination.'" "'.$target_object.'"`'."\n" && exit;
  }
  #one-file to one-folder
  if(-f $target_object && -d $likely_destination){
    file_to_folder($target_object , $likely_destination);
  }
  #one-folder to one-folder is EQUAL to EACH-file to one-folder
  if(-d $target_object && -d $likely_destination){
    folder_to_folder($target_object , $likely_destination);
  }
  return 1;
}
sub file_to_folder {
  my ($obj,$dest) = @_;
  my $withthese = openRecursiveGenieByFilenames({'f'=>[$obj],'d'=>[$dest]});
  my $bestlikelihood = finalScoreGenie({'f'=>$obj,'all'=>$withthese},{});
  # those -> $this
  execGenie($bestlikelihood);
  return 1;
}
sub openRecursiveGenieByFilenames {
  my ($session) = @_;
  while(my $lookupdir = shift @{$session->{'d'}}){
    $files_uD = crawler($lookupdir,{},{});
  }
  return $files_uD;
}
sub crawler {
  my ($d,$fh,$h) = @_;
  opendir(my $dh,$d) || die "Can't opendir $d: $!";
  my @files,@dirs;
  while (readdir $dh) {
    push(@files,"$d/$_") if -f "$d/$_";
    push(@dirs,"$d/$_/") if -d "$d/$_";
  }
  closedir $dh;
  $fh->{$_} = 1 foreach @files;
  my $lookupdir = shift  @dirs;
  $h->{$_} = 1  foreach  @dirs;
  if( length(@dirs)>0 ){return crawler($lookupdir,$fh,$h);}
  return $fh;
}
sub finalScoreGenie {
  my ($h,$scoreSheet) = @_;
  my ($f,$all) = ($h->{'f'},$h->{'all'});
  $scoreSheet->{$_} = [$f,1] foreach existsFileSomewhere($f,keys %$all);
  return $scoreSheet;
}
sub existsFileSomewhere {
  my $this = shift @_;
  my @isFound;
  push(@isFound,$_) if /$this/ foreach @_;
  return @isFound;
}
sub execGenie {
  my ($compare) = @_;
  while( my($k,$v)=each(%$compare) ){
    print `diff -sq "$v" "$k" `;
  }
  return 1;
}


sub folder_to_folder {
  my ($dest1,$dest2) = @_;
  my $withthese = openRecursiveGenieByFilenames({'f'=>[],'d'=>[$dest1]});
  file_to_folder($_,$dest2) if -f $_ foreach keys %$withthese;
  return 1;
}
