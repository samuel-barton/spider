#==============================================================================
#
# File: Hex.pm
#
# Created by: Samuel Barton
#
# Project: Spider (IMT card reader)
#
# Date: Summer 2016
#
# Description: This file handles the conversion of binary files to escaped hex
#              strings, and the conversion of escaped hex strings back into 
#              binary files. This is needed to enalbe using photos in the
#              database.
#==============================================================================

package Hex;
use v5.22;

#==============================================================================
#
# Function name: fileToHex
#
# Parameters: input_path - the path to the file to be converted
#
# Returns: an escaped hexadecimal string representing the file
#
# Description: This function generates the hexadecimal string representation of
#              a binary file using the 'od -xv' command and the 'sed' command.
#
#              od -xv prints out the entire file in hexadecimal (no duplicates
#              ignored).
#
#              sed 's/^[0-9]*//' removes the first token of digits from each 
#              line, thus getting rid of the byte count that od starts each 
#              line with.
#
#==============================================================================
sub fileToHex
{
    # get the first parameter, namely the file to convert to hex
    my $input_path = shift;

    # pipe the output this shell command into the filehandle 'input_file'
    open(input_file, "-|", "od -vx $input_path | sed 's/^[0-9]*//'");

    my $contents;

    # loop through the output, pulling out the four character blocks od 
    for my $line (<input_file>)
    {
        my @strings = split (/[^0-9a-f]/ , $line);

        for my $item (@strings)
        {
	    if (length $item > 1)
            {	
                $contents = $contents . $item;
            }
        }
    }

    close(input_file);

    # generate the hex string to put into the postgres database.
    my $escaped_hex = '\x' . $contents;

    # put it on the front of the array we are returning.

    return $escaped_hex;
}

sub __hexToArray
{
    my $hex_string = shift;
    my @hex_array;

    my $len = length ($hex_string);
    my $index = 1;

    until ($index == $len)
    {
        my $head = substr $hex_string, $index, 4;
        $index += 4;
	push @hex_array, $head;
    }

    return @hex_array;
}

sub hexToFile
{
    my $file_path = shift;
    my $escaped_hex = shift;
    $escaped_hex =~ s/\\x//;

    my @hex = __hexToArray($escaped_hex);

    open(output_file, ">:raw", "$file_path");
    for my $item (@hex)
    {
        my $rev = reverse $item;
	print output_file pack ("h4", $rev);
    }

    close(output_file);
}
1;
