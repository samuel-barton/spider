package Hex;
use v5.22;

sub fileToHex
{
    # get the first parameter, namely the file to convert to hex
    my $input_path = shift;

    open(input_file, "-|", "od -vx $input_path | sed 's/^[0-9]*//'");

    my $contents;
    my @hex;

    for my $line (<input_file>)
    {
        my @strings = split (/[^0-9a-f]/ , $line);

        for my $item (@strings)
        {
	    if (length $item > 1)
            {	
	    	push @hex, $item;
                $contents = $contents . $item;
            }
        }
    }

    close(input_file);

    # generate the hex string to put into the postgres database.
    my $escaped_hex = "x" . $contents;

    # put it on the front of the array we are returning.

    unshift @hex, $escaped_hex;

    return @hex;
}

sub hexToFile
{
    # ignore the escaped hex string which is the first piece of the array.
    my $ignore = shift;
    # hex string to write to file
    my @hex = @_;
 
    open(output_file, ">:raw", "output");
    for my $item (@hex)
    {
        my $rev = reverse $item;
	#(length $item < 2) or print output_file pack ("h4", $rev);
	print output_file pack ("h4", $rev);
    }

    close(output_file);
}
1;
