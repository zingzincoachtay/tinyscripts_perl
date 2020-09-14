#!/usr/bin/perl -w
use strict;
use warning;
my $current = &today(time);
my $param = {'rep'=>int rand(1024)
            ,'set'=>10
            ,'job'=>['while']
            ,'lap'=>{ 'for'=>[],'foreach'=>[],'foranon'=>[],'do'=>[],'while'=>[],'whileeach'=>[],'strlen'=>[],'strpos'=>[],'strind'=>[],'switch'=>[],'if'=>[] };
};

# http://baishui.info/orelly/linux/cgi/ch17_01.htm
# perldoc -q "Switch"
$param->{'job'} = &prompt($param->{'job'},$param->{'lap'});

&strenuous($param);
print &benchmark($param->{'rep'},$param->{'set'},$param->{'job'},$param->{'lap'});


sub prompt {
  my ($job,$lap) = @_;
  print 'It will compare'.join(',',@$job).". Okay? (Y/n)\n";
  my $no = <>; chomp $no;
  my $nojob = [];
  if $no =~ /no/i {
    print "Which two will you compare?\n";
    my $get = <>; chomp $get;
    ($job,$nojob) = &substitute_jobs($get,$lap);
    print 'These jobs will not be tested: '.join(',',@$nojob)."\n" if length(@$nojob)>0;
  }
  return $job;
}
sub substitute_jobs {
  my ($tasks,$lap) = @_;
  my %have = map {$_=>0} keys %$lap
  my ($n,$has,$hasnot) = (0,[],[]);
     push(@$has,$_) foreach (grep ( exists $have{$_}) split /[\s,]/,$tasks);
  push(@$hasnot,$_) foreach (grep (!exists $have{$_}) split /[\s,]/,$tasks);
  return \@has;
}
sub today {
  my ($sec,$min,$hour,$mday,$dmon,$year,$wday,$yday,$isdst) = gmtime(shift @_);
  my @weekday = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
  my @month = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
  $year = $year + 1900;
  $dmon += 1;
  $hour -= $isdst;
  return "$year-$dmon-$mday($weekday[$wday])$hour:$min:$sec";
}
sub benchmark {
  my ($n,$N,$job,$lap) = @_;
  my $result = {};
  $result->{$_} = &mean(@{$lap->{$_}}) foreach @{$job};
  my $fastest = &fastest($result);
  my $show_result = '';
  while(my($key,$val)=each(%{$result})){
    if ${$fastest}[0] eq $key { $show_result.=sprintf("%s:\t%.4f ms\n",$key,$val*1000); }
    else { $show_result.=sprintf("%s:\t%.4f ms (+%.2f)\n",$key,$val*1000, ($val/${$fastest}[1]-1)*100 ); }
  }
  return = <<RESULT;
  *** Average Execution Time are after $n reps and $N sets
  $show_result
  *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
RESULT
}
sub strenuous {
  my ($v) = @_;
  my ($rep,$set,$job,$lap) = ($v->{'rep'},$v->{'set'},$v->{'job'},$v->{'lap'});
  # https://perldoc.perl.org/perlsyn.html#Switch-statements
  SWITCH: for(@$job) {
        'for' && foreach(1 .. $set) { push(@{$lap->    {'for'}},    &test_for(0,$rep) )}
    'foreach' && foreach(1 .. $set) { push(@{$lap->{'foreach'}},&test_foreach(1,$rep) )}
    'foranon' && foreach(1 .. $set) { push(@{$lap->{'foranon'}},&test_foranon(1,$rep) )}
           'do' && foreach(1 .. $set) { push(@{$lap->       {'do'}},       &test_do(1,$rep) )}
        'while' && foreach(1 .. $set) { push(@{$lap->    {'while'}},    &test_while(0,$rep) )}
    'whileeach' && foreach(1 .. $set) { push(@{$lap->{'whileeach'}},&test_whileeach(1,$rep) )}
    'arrlen' &&
    'arrind' &&
    /^strpos$/i && do{};
    # string search, 'strpos' vs regex
    # string concat, .(dot) operator vs "(double quotation) expansion
    # conditional, serial 'if's vs 'elseif's vs switch

    /^(str)?len(gth)?s?/i && foreach(1 .. $rep) {
      push(@{$lap->{'strlen'}}, &test_strlen(&word) )};
    /^(str)?(regex(?=len)|regex(?<len))/i && foreach(1 .. $rep) {
      push(@{$lap->{'strlenregex'}}, &test_strlenregex(&word) )};
  }
}
sub test_for     { my ($k,$n)=@_; my $p=time; for($k=0;$k<$n;$k++){ &job(); } return dev(time,$p,$n); }
sub test_foreach { my ($j,$n)=@_; my $p=time; foreach my $loop ($k .. $n){ &job(); } return dev(time,$p,$n); }
sub test_foranon { my ($i,$n)=@_; my $p=time; foreach ($k .. $n){ &job(); } return dev(time,$p,$n); }
sub test_do         { my ($j,$n)=@_; my $p=time; do{ &job();$j++; }while($j<$n); } return dev(time,$p,$n); }
sub test_while      { my ($k,$n)=@_; my $p=time; while($k<$n){ &job();$k++; } return dev(time,$p,$n); }
sub test_whileeach  { my ($i,$n)=@_; my %h=map {$_=>0} ($i .. $n); my $p=time; while(my($k,$v)=each(%h)){ &job(); } return dev(time,$p,$n); }
sub test_arrlen { my ($n)=@_; my $box=&sets($n); my $p=time; length(@$box); return dev(time,$p,$n); }
sub test_arrind { my ($n)=@_; my $box=&sets($n); my $p=time; $#$box+1; return dev(time,$p,$n); }

sub test_strpos {	my $str="potassium"; my $loop; my ($stop) = @_;# print "$stop\n" if $stop+$stop > $upper_limit;
  foreach $loop (1..$stop) { 1 if( index($str,'sium')>0 ); } }
sub test_strpos_regex {	my $str="potassium"; my $loop; my ($stop) = @_;# print "$stop\n" if $stop+$stop > $upper_limit;
  foreach $loop (1..$stop) { 1 if( $str=~/sium$/ );  } }
sub test_strlen { my ($s)=@_; return length($s); }
sub test_strlen_regex { my ($s)=@_; my $t=substr($s,0,-1); $s=~/$t/; return pop @+; }
sub test_strlen0 { my ($s)=@_; return 1 if length($s)==0; }
sub test_streq0 { my ($s)=@_; return 1 if $s eq ''; }
sub test_strregex0 { my ($s)=@_; return 1 if $s!~/./; }
sub test_length_regex {	 }

#sub job { return (rand>0) ? 1 : 0; }
sub job { return rand; }
sub word { return 'Taumatawhakatangihangakoauauotamateaturipukakapikimaungahoronukupokaiwhenuakitanatahu'; }
sub sets { my ($N)=@_; my $box[]; push(@box, &job() ) foreach (1 .. $N); return $box; }
sub mean { return (length(@_)==0) ? -1234 : (sum(@_)/length(@_)); }
sub sum { my $ans=0; $ans+=$_ foreach (@_); return $ans; }
sub dev { my ($x,$xhat,$n) = @_; return ($x-$xhat)/$n; }
sub fastest { my $Flash=["",0]; while(my($key,$val)=each(%{$_})){ $Flash=[$key,$val] if $$Flash[0] eq "" || $val<$$Flash[1]; } return $Flash; }
