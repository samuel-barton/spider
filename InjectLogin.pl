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

my %logins = {};
my @logged_in_users;

say "Insert fake login events.";
say "--------------------------------------------------------------";
&printUsers();
say "--------------------------------------------------------------";
say "Enter the number of the user you'd like to inject a login for.";

while (1)
{
    print "number: ";
    my $number = <stdin>;
    chomp($number);
    # get the needed info from the 
    if (defined $logins{$number} and not &contains($number, @logged_in_users))
    {
        say "Login for $logins{$number} injected.";
        push @logged_in_users, $number;
        Persist::login($number);
    }
    elsif (defined $logins{$number})
    {
        say "$logins{$number} already logged in.";
    }
}

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
