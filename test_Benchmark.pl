
use Benchmark;

my $k;
my $next = 1;
for($k=0;$k<9;$k++){
  $next *= 10; print "$next\n";
  timethese (10000, {
                 for => <<'end_for',
                   my $loop;
                   for ($loop=1; $loop <= $next; $loop++) { 1 }
end_for
                 foreach => <<'end_foreach'
                   my $loop;
                   foreach $loop (1..$next) { 1 }
end_foreach
                } );
}

