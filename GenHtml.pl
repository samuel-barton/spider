#! /usr/bin/perl

use v5.14;

#==============================================================================
#
# Name GenHtml.pl
#
# Project: IMT card reader
#
# Created by: Sameul Barton
#
# Description: This program will handle the creation of the html page(s) which
# will be used by the CardReader.pl program to interface with the end users.
#
#==============================================================================

# paths to html files
my $password_output_path = 'html/password.html';
my $success_output_path = 'html/success.html';
my $fail_output_path = 'html/fail.html';

my $password_input_path = 'html/template/password.html';
my $success_input_path = 'html/template/success.html';
my $fail_input_path = 'html/template/fail.html';

&password("jane");

#==============================================================================
#
# Function name: password
#
# parameters: username
#
# Returns: void
#
# Description: this function generates the custom password entry page for each
#              individual user.
#
#==============================================================================
sub password
{
    # get parameter.
    my $username = $_[0];

    # open the input and output files
    my $input_file = &read($password_input_path);
    my $output_file = &write($password_output_path);

    # loop through the input file, and write each line to the output file, 
    # substituting the parameter for every instance of USER. 
    for my $line (<$input_file>)
    {
	chomp($line);
	$line =~ s/USER/$username/;
        say $output_file $line;
    }

    # close both files.
    close($input_file);
    close($output_file);
}

#==============================================================================
#
# Function name: begin
#
# parameters: file handle to output.html
#
# Returns: void
#
# Decription: this function prints out the header for the top of the html file.
#
#==============================================================================
sub begin
{
    my $fh = $_[0];
    say $fh "<html>";
    say $fh "<body>";
}

#==============================================================================
#
# Function name: end
#
# parameters: file handle to output.html
#
# Returns: void
#
# Decription: this function prints out the footer for the bottom of the html
# file.
#
#==============================================================================
sub end
{
    my $fh = $_[0];
    say $fh "</html>";
    say $fh "</body>";
}


#==============================================================================
#
# Function name: write
#
# parameters: path
#
# Returns: file handle to the file specified by $path
#
# Decription: this function opens the file for writing.
#
#==============================================================================
sub write
{ 
    my $path = $_[0];

    open(my $fh, ">", $path) or die "Couldn't open file: $!";

    return $fh;
}

#==============================================================================
#
# Function name: read
#
# parameters: path
#
# Returns: file handle to the file specified by $path
#
# Decription: this function opens the file for reading.
#
#==============================================================================
sub read
{ 
    my $path = $_[0];

    open(my $fh, "<", $path) or die "Couldn't open file: $!";

    return $fh;
}
