hexToFile(fileToHex(shift));

sub fileToHex
{
    # get the first parameter, namely the file to convert to hex
    my $input_path = shift;

    open(input_file, "-|", "od -x $input_path | sed 's/[0-9]*//'");

    my $contents;
    my @hex;

    for my $line (<input_file>)
    {
        my @strings = split (/ |\t|\n/ , $line);
        #print @strings;

        for my $item (@strings)
        {
            push @hex, $item;

            $contents = $contents . $item;
        }
    }

    close(input_file);

    return @hex;
}

sub hexToFile
{
    # hex string to write to file
    my @hex = @_;
    
    open(output_file, ">:raw", "output");
    for my $item (@hex)
    {
        $rev = reverse $item;
        (length $item < 2) or print output_file pack ("h*", $rev);
    }

    close(output_file);
}
