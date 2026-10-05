use strict;
use warnings;

# Enter one number per line. An empty line or end-of-file finishes input.
# Invalid lines are reported to STDERR and ignored.
my @numbers;

while (my $line = <STDIN>) {
    chomp $line;
    $line =~ s/\r$//;
    last if $line =~ /^\s*$/;

    if ($line =~ /^\s*[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\s*$/) {
        push @numbers, 0 + $line;
    } else {
        warn "Skipped invalid value: $line\n";
    }
}

if (!@numbers) {
    print "No valid numbers were entered.\n";
    exit 0;
}

my $sum = 0;
my $minimum = $numbers[0];
my $maximum = $numbers[0];

for my $number (@numbers) {
    $sum += $number;
    $minimum = $number if $number < $minimum;
    $maximum = $number if $number > $maximum;
}

my $count = scalar @numbers;
my $average = $sum / $count;

print "Count: $count\n";
printf "Sum: %.10g\n", $sum;
printf "Average: %.10g\n", $average;
printf "Minimum: %.10g\n", $minimum;
printf "Maximum: %.10g\n", $maximum;
