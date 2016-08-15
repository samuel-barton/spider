#==============================================================================
#
# File: ShowLoggedInUsers.pl
#
# Project: Spider
#
# Created by: Samuel Barton
#
# Date: Summer 2015
#
# Description: This program does one simpe thing, it uses the Persist.pm, 
#              GenHTML.pm, and Hex.pm Perl libraries to generate an html page
#              which shows the list of logged in users.
#
#==============================================================================

use v5.14;
use Persist;
use GenHTML;
use Hex;

-e "www/img" or mkdir "www/img";

do
{
    # create a connection to the database.
    my $database = Persist::spawn();

    # get the list of logged in users from the databse.
    my @logged_in_users = $database->getLoggedInUsers();

    my @return;
    for my $user (@logged_in_users)
    {
        my $login_time = $database->getLoginTime($user);    

        (my $name, my $password, my $photo) = $database->getInfo($user);

        Hex::hexToFile("www/img/$name.jpg", $photo);

        my @output = ($name, $login_time, "img/$name.jpg");

        push @return, \@output;
    }

    GenHTML::genLoggedIn(@return);

    sleep 10;
}
while (1);
