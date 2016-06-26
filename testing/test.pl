use v5.14;
use FindBin;

my $path = "$FindBin::Bin/CONNECTED.dev";
open (handle, "<", $path) or die "$!";

for my $line (<handle>)
{
    chomp($line);
    print $line."\n";
}

close (handle);
