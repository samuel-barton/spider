#!/usr/bin/env perl

use Fcntl;
use POSIX;
use Parallel::Jobs;
use FindBin;
use IO::Select;
use DBI;
use Persist;

require 'GenHtml.pl';

#===============================================================================
#
# Name: WebCardReader.pl
#
# Version: 3.0 of the smartCardReader.pl program
#
# Written by: Samuel Barton
#
# Date: spring/summer 2014
#
# Project: RF Card Reader
#
# Description: This script logs users in and out of some area using a RF card
#              reader. It also logs each login / logout to a log file which 
#              will later be pulled from when data is to be sent to NAGIOS and
#              Security Onion.
#
#              It reads from a named pipe which a python script writes to. The
#              python script is run in the background by Parallel::Jobs and it
#              reads the data from the card reader and writes it to the pipe.
#              Thee data is read from the pipe instead of straight from STDIN
#              for security reasons (if the data were read from STDIN directly,
#              or even passed from one program to the other via STDIN, then it
#              would be possible for a malicious user to mimic the card reader 
#              via typing in the card number (a 10 digit decimal string).
#
#              When the program starts, it reads in the list of known users
#              and their credentials; then it reads in the list of currently
#              logged in users (from the last time the program ran).
#
#              Login: - card number is recognized
#
#              The user is asked for their credentials, and is given  three 
#              chaces to enter  his or her password. He or she is then required
#              to enter a message describing the purpose of his or her visit
#              to the workspace. Upon entering a purpose to their visit, the 
#              login is logged and the user is added to the hash of currently 
#              logged in users.
#
#              Logout:
#
#              The time the user logged in is pulled from the value portion of
#              the hash of currently logged in users. Then the user is deleted
#              from the list of logged in users. The length of time the user
#              was logged in is calculated, and a successful logout is logged.
#              Finally, a message prints to the screen telling the user that 
#              they have been successfully logged out.
#
#              The format for the date and time portion of the log entry will
#              look like this: <month> <day> <year> <hr 0..23> <min> <seconds>
#              This is the command used to get the date in that format:
#                  date +%b\ %d\ %Y\ %H:%M:%S
#
#              At the end of each iteratoin of the main loop, whether a login
#              or a logout occurred, any card numbers received after the first
#              one are discarded, and the list of currently logged in users is
#              written to a text file.
#
#              The program will do the following things
#              - ask the user to swipe their card
#              - ask for a password
#              - state that the user entered the area at <current time>
#              - ask the user to state their purpose for entering the area
#
#              The following data will be logged (for a login):
#              - The user who entered
#              - The date and time they entered
#              - Their stated purpose
#
#              The log will look like so (for a login)
#              <log info> <date> login <username> <purpose>
#
#              The following data will be logged (for a logout):
#              - The user who exited
#              - How long they were logged in
#
#              The log will look like so (for a logout)
#              <log info> <date> logout <username> <length_of_time_logged_in>
#
#              The program will also keep track of users who are currently
#              logged in, and when they scan their card after being perviously
#              logged in a message will appear stating that they have been
#              logged out, and both the user who logged out, and the time they
#              logged out, will be logged as well.
#
#              FindBin::bin is used to find the directory in which this program
#              is currently running.
#
#===============================================================================
# - Sentinel for the infinite loop which is the basis for this script
my $stop = 0;
# - path to the list of recognized user ids
my $recognized_user_path = "RECOGNIZED_IDS.txt";
# - the path to tddddhe log file
my $log_path;
# - The hash of card #s and their corresponding user ids
my %recognized_users;
# - The hash of passwords (keyed by user id)
my %passwords;
# - The string reprisenting an unauthorized card #
my $UNAUTHORIZED_CARD = "!";
# - The name of the card reader being read from
my $card_reader_name = "card-reader";
# - The Vendor ID of the card reader being read from
my $vendor_id = "13ba";
# - The Product ID of the card reader being read from
my $product_id = "0018";
# - Sentinel for skipping the remainder of the steps of the loop 
my $restart = 0;
# - The path to the named pipe where the card numbers come from
my $fifo_path = "card-id-num.fifo";
# - The hash of currently logged in users
my %logged_in_users;
# - The path to the file which holds a copy of %logged_in_users
my $logged_in_users_path = 'LOGGED_IN_USERS.txt';
# - the format for getting dates for the timestamp portion of the log entry
my $date_format = 'date +%b\ %d\ %Y\ %H:%M:%S';

# read in the list of recognized users from the file 
open (id_list, "<", $recognized_user_path) or die "couldn't open file: $!";

for my $line (<id_list>)
{
    chomp($line);
    # pull out the card #, user id, and passwrod from the file
    (my $card_num, my $user_id, my $pwd) = 
    ($line =~ /^(\d{10}) => ([a-zA-Z0-9]+) pwd: ([a-zA-Z0-9]+)$/);
    $recognized_users{$card_num} = $user_id;
    $passwords{$user_id} = $pwd;
}
close(id_list);

# Read in the list of currently logged in users
open(logged_in_users, "<", $logged_in_users_path);

for my $line (<logged_in_users>)
{
    chomp($line);
    # pull out the user name, and the time they logged in from the file
    (my $user, my $login_time) = ($line =~ /^([a-zA-z0-9]+) (\d+)$/);
    $logged_in_users{$user} = $login_time;
}


# Start the python script which reads data from the card reader 
Parallel::Jobs::start_job({stderr_capture => 1 | stdout_capture => 1}, 
                          "sudo $FindBin::Bin/read.py");

# Create a named pipe called password.fifo
my $password_fifo_path = "www/password.fifo";
# Create a named pipe called purpose.fifo
my $purpose_fifo_path = "www/purpose.fifo";

&createFifo($password_fifo_path);
&createFifo($purpose_fifo_path);

# loop infinitely logging users in and out as they swipe their cards and enter
# their credentials.
until ($stop)
{
    $restart = 0;

    &setStatus("false");

    # Once data is received, store it in $data.
    open(fifo, "<", $fifo_path);
    my $data = <fifo>;
    chomp($data);

    # find out if the card number is recognized.
    my $user_name = &isAuthorizedUser($data);

    # If the user is currently logged in
    if (defined $logged_in_users{$user_name})
    {
        # aquire the time they logged in.
        my $old_time = $logged_in_users{$user_name};

        # log the user out.
        delete $logged_in_users{$user_name};

        # get the number of seconds since the epoch.
        my $time = `date +%s`;
        chomp($time);

        # calculate how long the user was logged in.

        # First, calculate the number of seconds since the user logged in.
        # Then convert that to hours to get the number of hours elapsed.
        # Next, convert $len to minutes, then subtract the number of hours
        # (converted to minutes).
        # Finally, subtract the number of hours (converted to seconds), and
        # the number of minutes (converted to seconds) from $len.
        #
        # Note, the use of POSIX::floor(<expression>) is intended to
        # provide us with integer values (instead of floating point).
        my $len = $time - $old_time;
        my $hr_len = POSIX::floor(($len / (60 * 60)));
        my $min_len = POSIX::floor((($len / 60) - ($hr_len * 60)));
        my $sec_len = 
        POSIX::floor(($len - (($hr_len * 60 * 60) + ($min_len * 60))));

        # Make sure the log path is correct
        &generatePath();
        # determine whether or not the current log path references an existing
        # file.
        my $status = -e $log_path;

        open (LOG, ">>", $log_path);

        my $date = `$date_format`;
        chomp ($date);
        print LOG "$card_reader_name $vendor_id:$product_id $date";
        print LOG " logout $user_name";
        printf LOG " %02d:%02d:%02d", $hr_len, $min_len, $sec_len;
        print LOG "\n";

        close(LOG);

        # Fix the symbolic links
        unless ($status)
        {
            &setupLinks();
        }

        # inform the user that they have been logged out
        &setStatus("logout");
        &parseLogout($user_name);
        sleep (3);
    }
    # if the user is not logged in and the id is recognized
    elsif ($user_name ne $UNAUTHORIZED_CARD)
    {        
        my $count = 0;
        my $password = "";

        &parsePassword($user_name);
        &setStatus("true");

	    # give the user three chances to enter their password.
	    until (($passwords{$user_name} eq $password) or $count == 3)
        {
            # open the password pipe and read its value (this will block till
            # something is written to the pipe.
            open (password_fifo, "<", $password_fifo_path) or 
            die "couldn't open file: $!";

            $password = <password_fifo>;
            close(password_fifo);
            chomp($password);

            &setStatus("continue");
	        $count++;
        }
       
        # If the password isn't correct at this point the user has exhausted 
        # their chances and this session will exit after the failed attempt is 
        # logged. Also the welcome page will be reloaded.
        if ($passwords{$user_name} ne $password)
        {
            &parseFail($user_name);

            &setStatus("false");

            # log the error and restart the whole process
            &logError("password does not match username.");
            $restart = 1;
        }

        unless ($restart)
        {
            &parseStatus($user_name);

            &setStatus("true");

            open(purpose_fifo, "<", $purpose_fifo_path) or 
            die "couldn't open file: $!";

            my $purpose = <purpose_fifo>;
            close(purpose_fifo);
            chomp($purpose);

            &setStatus("continue");

            # keep asking the user to enter their purpse until they
            # enter data.
            until (length($purpose) > 0)
            {
                open(purpose_fifo, "<", $purpose_fifo_path) or 
                die "couldn't open file: $!";
                my $purpose = <purpose_fifo>;
                chomp($purpose);
            }

            &parseSuccess($user_name);

            # make sure the log path is correct
            &generatePath();
            # determine whether or not the current log path references an
            # existing file.
            my $status = -e $log_path;

            open (LOG, ">>", $log_path) or die "couldn't open logfile: $!";
            my $date = `$date_format`;
            chomp ($date);

            # if this code is executing, thne the user has successfully
            # logged in and should be added into the list of logged in 
            # users.
            my $time = `date +%s`;
            chomp($time);
            $logged_in_users{$user_name} = $time;

            # The name of the card-reader, and the vendor and product ids
            # need to be able to change with different devices.
            print LOG "$card_reader_name $vendor_id:$product_id $date".
                  " login $user_name $purpose\n";
            close(LOG);

            # fix the symbolic links
            unless ($status)
            {
                &setupLinks();
            }
        }
    }

    # We leave the fifo open for this long because this way if the user swipes
    # his or her card more than once, the program won't act strangely.
    my $ignore = <fifo>;
    close(fifo);

    # open the file to write the list of logged in users 
    open(logged_in_users, ">", $logged_in_users_path);
    for my $i (keys %logged_in_users)
    {
        print logged_in_users "$i ".$logged_in_users{$i}."\n";
    }
    close(logged_in_users);
}

#==============================================================================
#
# Method name: getLoggedInUsers
#
# Parameters: none
#
# Returns: %logged_in_users - the users currently logged in.
#
# Description: This method returns the hash of currently logged in users.
#
#==============================================================================
sub getLoggedInUsers
{
    return %logged_in_users;
}

#==============================================================================
#
# Method name: generatePath
#
# Parameters: none
#
# Returns: void
#
# Description: This method generates the path for the log file.
#
#==============================================================================
sub generatePath
{
    my $log_date = `date +%b-%d-%Y`;
    chomp ($log_date);
    $log_path = "$FindBin::Bin/logs/".$log_date.'-'.$card_reader_name.'.log';
}

#==============================================================================
#
# Method name: isAuthorizedUser
#
# Parameters: the id # from the card reader
#
# Returns: $UNAUTHORIZED_CARD - if the card # is not on the list
#          $recognized_users{$card_num} - if the card # is on the list
#
# Description: This method determines whether or not the id # is on the list
#              of authorized ids. if it is, the method returns the username
#              associated with the id it was passed, if not, then the method
#              returns a string signifying an unauthorized card number.
#
#==============================================================================
sub isAuthorizedUser
{
    # get the id # which was passed in as a parameter
    my $card_num = $_[0];

    # loop through the list of known id's
    for my $i (keys %recognized_users)
    {
        # if the id # matches one of recognized id's, return the username 
        # associated with this card #
        if ($card_num eq $i)
        {
            return $recognized_users{$card_num}; 
        }
    }

    # if the id # does not match any of the recognized id's, return the string
    # reprisenting an unauthorized card
    return $UNAUTHORIZED_CARD;
}

#==============================================================================
#
# Method name: logError
#
# Parameters: $error_message - a conscise description of the error
#
# Returns: void
#
# Description: This method enables easy logging of error messages.
#
#==============================================================================
sub logError
{
    my $error_message = $_[0];

    # make sure the log path is correct
    &generatePath();
    my $status = -e $log_path;

    open (LOG, ">>", $log_path) or die "couldn't open logfile: $!";
    my $date = `$date_format`;
    chomp ($date);
    print LOG "$card_reader_name $vendor_id:$product_id $date".
              " error: $error_message\n";
    close(LOG);

    # Fix the symbolic links
    unless ($status)
    {
        &setupLinks();
    }
}

#==============================================================================
#
# Method name: setupLinks
#
# Parameters:
#
# Returns: void
#
# Description: This method fixes the symbolic links between the log file being
#              written to and the "current" log file in logs/current
#
#==============================================================================
sub setupLinks
{
    unlink("$FindBin::Bin/logs/current/current-$card_reader_name.log");
    symlink("$log_path",
            "$FindBin::Bin/logs/current/current-$card_reader_name.log");
}

#==============================================================================
#
# Method name: setStatus
#
# Parameters status (true, false, continue)
#
# Returns: void
#
# Description: This subroutine sets the value of 'status.txt', a file used by 
#              the php and javascript/AJAX programs running on the apache 
#              server making the web interface work.
#
#==============================================================================
sub setStatus
{
    my $status = $_[0];

    open(STATUS, ">", "www/status.txt") or 
    die "couldn't open file: $!";

    print STATUS $status;

    close(STATUS);
}

#==============================================================================
#
# Method name: createFifo
#
# Parameters fifo_path
#
# Returns: void
#
# Description: Creates a fifo with the path passed in as a parameter if it 
#              doesn't exist already.
#
#==============================================================================
sub createFifo
{
    my $fifo_path = $_[0];

    # if the fifo does not exist
    unless ( -p $fifo_path )
    {
        # remove any file with the name we are going to use.
        unlink($fifo_path);
        # create the fifo, making it read/write for everyone.
        system("mkfifo -m 666 $fifo_path");
    }
}

#==============================================================================
#
# Method name: connectToDB
#
# Parameters: none
#
# Returns: void
#
# Description: This method handles establishing the connection to the database
#
#==============================================================================
sub connectToDB
{
    my $driver = "postgres";
    my $database = "cardreader";
    my $host = "10.200.40.3";
    my $dsn = "DBI:$driver:database=$database;host=$host";
    my $userid = "postgres";
    my $password = "card_reader";

    my $dbh = DBI_>connect($dsn, $userid, $password) or die $DBI::errstr;

    return $dbh;
}

#==============================================================================
#
# Method name: login
#
# Parameters: id        - the users RFID number
#             time      - the time the user logged in
#             purpose   - the users stated message for logging in 
#
# Returns: void
#
# Description: This method generates and executes the SQL statements needed to 
#              update the database to reflect a user login. This means that
#              the access_log table will need a new row, and the whose_in table
#              will also need a new row.
#
#==============================================================================
sub login
{
    my $id = $_[0];
    my $time = $_[1];
    my $purpose = $_[2];
}

#==============================================================================
#
# Method name: logout
#
# Parameters: id                - the users RFID number
#             time              - the time the user logged in
#             length_logged_in  - amount of time since login
#
# Returns: void
#
# Description: This method generates and executes the SQL statements needed to 
#              update the database to reflect a user logout. This means that
#              the access_log table will need a new row, and the whose_in table
#              will need a row removed.
#
#==============================================================================
sub logout
{
    my $id = $_[0];
    my $time = $_[1];
    my $length_logged_in = $_[2];
}
