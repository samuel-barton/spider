#! /usr/bin/perl

package GenHTML;
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
my $password_output_path = 'www/password.php';
my $success_output_path = 'www/success.php';
my $status_output_path = "www/status.php";
my $logout_output_path = "www/logout.php";
my $fail_output_path = 'www/fail.php';

my $password_input_path = 'html/template/password.php';
my $success_input_path = 'html/template/success.php';
my $status_input_path = "html/template/status.php";
my $fail_input_path = 'html/template/fail.php';
my $logout_input_path = 'html/template/logout.php';

#==============================================================================
#
# Function name: parseFail
#
# parameters: username
#
# Returns: void
#
# Description: this function generates the custom status login fail page for
#              each individual user.
#
#==============================================================================
sub parseFail
{
    my $username = $_[0];
    &parseUser($username, $fail_input_path, $fail_output_path);
}

#==============================================================================
#
# Function name: parseLogout
#
# parameters: username
#
# Returns: void
#
# Description: this function generates the custom logout  page for
#              each individual user.
#
#==============================================================================
sub parseLogout
{
    my $username = $_[0];
    &parseUser($username, $logout_input_path, $logout_output_path);
}

#==============================================================================
#
# Function name: parsePassword
#
# parameters: username
#
# Returns: void
#
# Description: this function generates the custom password entry page for each
#              individual user.
#
#==============================================================================
sub parsePassword
{
    my $username = $_[0];
    &parseUser($username, $password_input_path, $password_output_path);
}


#==============================================================================
#
# Function name: parseUser
#
# parameters: username
#             input path
#             output path
#
# Returns: void
#
# Description: This function parses a file and puts in a personalized username
#              in place of the placeholder in the template file.
#
#==============================================================================
sub parseUser
{
    # get parameter.
    my $username = $_[0];
    my $input_path = $_[1];
    my $output_path = $_[2];

    # open the input and output files
    my $input_file = &read($input_path);
    my $output_file = &write($output_path);

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
# Function name: parseStatus
#
# parameters: username
#
# Returns: void
#
# Description: this function generates the custom status entry page for each
#              individual user.
#
#==============================================================================
sub parseStatus
{
    my $username = $_[0];
    &parseUser($username, $status_input_path, $status_output_path);
}

#==============================================================================
#
# Function name: parseSuccess
#
# parameters: username
#
# Returns: void
#
# Description: this function generates the custom success page for each
#              individual user.
#
#==============================================================================
sub parseSuccess
{
    my $username = $_[0];
    &parseUser($username, $success_input_path, $success_output_path);
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
1;
