use v5.14;

my $fifo_path = "card-id-num.fifo";

open (fifo, '<', $fifo_path) or die "error.";
my $data = <fifo>;
say $data;
