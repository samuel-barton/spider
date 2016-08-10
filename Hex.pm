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
use v5.14;

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
    open(input_file, "-|", "od -t x1 -v $input_path | sed 's/^[0-9]* *//'");

    my $contents;

    # append each line of data pulled in from the shell command to contents.
    for my $line (<input_file>)
    {
        chomp($line);
        $contents = $contents . $line;
    }

    close(input_file);

    # generate the escaped hex string to put into the postgres database.
    my $escaped_hex = '\x' . $contents;

    return $escaped_hex;
}

#==============================================================================
#
# Function name: hexToFile
#
# Parameters: file_path - the path to the output file
#             escaped_hex - the escaped hex from the database
#
# Returns: void
#
# Description: This function takes the escaped hex from the database and writes
#              it to a file. This string is in raw hex, and is not a string
#              representation of hex, thus there is no need for using pack() to
#              convert the string to hex.
#
#==============================================================================
sub hexToFile
{
    my $file_path = shift;
    my $escaped_hex = shift;
    $escaped_hex =~ s/\\x//;

    open(output_file, ">:raw", "$file_path");
    print output_file $escaped_hex;

    close(output_file);
}
1;
