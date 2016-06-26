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

# the name of the html file we are outputting to.
my $output_path = "output.html";

# &welcome();
&password();

#==============================================================================
#
# Function name: welcome
#
# Parameters: none
#
# returns: void
#
# Description: This page simply prints the welcome screen asking the user to
#              swipe their card.
#
#==============================================================================
sub welcome
{
    my $output_file = &openFile();

    &begin($output_file);

    say $output_file "<h1>Welcome!</h1>";
    say $output_file "<h2><i>Please scan your tag.</i></h2>";

    &end($output_file);
    close($output_file);
}


#==============================================================================
#
# Function name: password
#
# parameters: none
#
# Returns: void
#
# Decription: this function prints out the header for the top of the html file.
#
#==============================================================================
sub password
{
    my $output_file = &openFile();

    &begin($output_file);

    say $output_file "<form>";
    say $output_file "password:<br>";
    say $output_file "<input type=\"text\" name=\"password\"><br>";
    say $output_file "</form>";

    &end($output_file);

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
# Function name: openFile
#
# parameters: none
#
# Returns: file handle to output.html
#
# Decription: this function opens the output file for writing.
#
#==============================================================================
sub openFile
{ 
    open(my $fh, ">", $output_path) or die "Couldn't open file: $!";

    return $fh;
}
