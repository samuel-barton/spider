#==============================================================================
#
# File name: InjectLogins.pl
#
# Created by: Samuel Barton
#
# Project: Spider
#
# Date: Summer 2016
#
# Description: This program is used to inject fake logins into the database.
#
#==============================================================================

use v5.14;
use Persist;
use GenHTML;

# create a hash for the user ID's we want, and find out what users are logged 
# in to the database already.
my %logins = {};
my @logged_in_users = Persist:getLoggedInUsers();

# Print a welcome message and the list of users we have to inject logins for.
say "Insert fake login events.";
say "--------------------------------------------------------------";
&printUsers();
say "--------------------------------------------------------------";
say "Enter the number of the user you'd like to inject a login for.";

# loop until all the users we can inject have been injected.
$injections = 0;
until ($injections == 10)
{
    # get the number of the user to inject a login for
    print "number: ";
    my $number = <stdin>;
    chomp($number);
    # see if said user is already logged in, and if not, log them in.
    if (defined $logins{$number} and not &contains($number, @logged_in_users))
    {
        say "Login for $logins{$number} injected.";
        push @logged_in_users, $number;
        Persist::login($number);
        $injections++;
    }
    elsif (defined $logins{$number})
    {
        say "$logins{$number} already logged in.";
    }
}
#===============================================================================
#
# Function name: contains
#
# Parameters: item  - the item to check for in the array
#             array - the array to search through
#
# Returns: 1 if array contains item, 0 otherwise
#
# Description: This function checks through an array to seee if it contains
#              some item.
#
#==============================================================================
sub contains
{
    my $item = shift;
    my @list = @_;

    for my $thing (@list)
    {
        if ($thing eq $item)
        {
            return 1;
        }
    }
    return 0;
}

#===============================================================================
#
# Function name: printUsers
#
# Parameters: none
#
# Returns: void
#
# Description: This function gets the list of users to inject from a file, and
#              prints them to the screen.
#
#==============================================================================
sub printUsers
{
    my $in_file = GenHTML::read("pseudonyms.txt");

    for my $line (<$in_file>)
    {
        (my $name, my $pw, my $id) = split(",", $line);

        $logins{$id} = $name;
        say "$id.\t\t$name";
    }
}
