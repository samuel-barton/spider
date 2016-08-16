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

# make sure that the images directory exists, and if it doesn't create it.
-e "www/img" or mkdir "www/img";

do
{
    # get the list of logged in users from the databse.
    my @logged_in_users = Persist::userList()s

    # empty array which we will use for return value.
    my @return;

    # loop through the logged in users, getting the needed info about them,
    # and generating an array of arrays where each subarray contains the users
    # name, time of login, and path to their photo.
    for my $user (@logged_in_users)
    {
        # get login time from the database
        my $login_time = Persist::getLoginTime($user);    

        # get the needed info about the user from the database
        (my $name, my $password, my $photo) = Persist::getInfo($user);

        # write the users photo to a file
        Hex::hexToFile("www/img/$name.jpg", $photo);

        # generate the array with the users info
        my @output = ($name, $login_time, "img/$name.jpg");

        # add that to the array we are passing to the function which will 
        # generate the html page we need.
        push @return, \@output;
    }

    GenHTML::genLoggedIn(@return);

    # recreate the page in 10 seconds.
    sleep 10;
}
while (1);
