#!/usr/bin/env perl

use v5.14;
use Fcntl;
use POSIX;
use Parallel::Jobs;
use FindBin;
use IO::Select;
use Persist;

require 'GenHtml.pl';

#===============================================================================
#
# Name: Spider.pl
#
# Version: 4.0 of the smartCardReader.pl program
#
# Written by: Samuel Barton
#
# Project: Spider
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
#              <log info> <date> logout <username> 
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

# - the path to the log file
my $log_path;
# - The string reprisenting an unauthorized card #
my $UNAUTHORIZED_CARD = "";
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
my @logged_in_ids;
# - the format for getting dates for the timestamp portion of the log entry
my $date_format = 'date +%b\ %d\ %Y\ %H:%M:%S';
# - The persistance object used to access the database
my $database = Persist->spawn();

# Get list of currently logged in users from the database.
@logged_in_ids = $database->getLoggedInUsers();

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
    my $id = <fifo>;
    chomp($id);

    # find out if the card number is recognized.
    (my $user_name, my $real_password, my $photo) = &isAuthorizedUser($id);

    # If the user is currently logged in
    if (&loggedIn($id))
    {
        &logout($user_name, $id);

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
	    until (($password eq $real_password) or $count == 3)
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
        if ($real_password ne $password)
        {
            &parseFail($user_name);

            &setStatus("false");

            # log the error and restart the whole process
            &logError($id, "password does not match.");
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

            # log the user in.
            &login($id,$user_name,$purpose);
        }
    }

    # We leave the fifo open for this long because this way if the user swipes
    # his or her card more than once, the program won't act strangely.
    my $ignore = <fifo>;
    close(fifo);
}

#==============================================================================
#
# Method name: loggedIn
#
# Parameters: id - the id being checked
#
# Returns: 1 - id is logged in, 0 - id isn't logged in
#
# Description: This method searches the list of logged in users to see if the 
#              ID its been passed is logged in.
#
#==============================================================================
sub loggedIn
{
    my $id = shift;

    for my $item (@logged_in_ids)
    {
        if ($id eq $item)
        {
            return 1;
        }
    }

    return 0;
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
# Returns: ("", "", "") - if the user is not in the database.
#          (username, password, photo) - if the user is.
#
# Description: This method polls the database for the users information based
#              on their card number.
#
#==============================================================================
sub isAuthorizedUser
{
    # get the id # which was passed in as a parameter
    my $card_num = $_[0];

    # get the information on this user from the databse
    my @res = $database->getInfo($card_num);

    if (scalar(@res) == 0) 
    {
        @res = ("","","");
    }

    return @res;
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
    my $id = shift;
    my $error_message = shift;

    # make sure the log path is correct
    &generatePath();
    my $status = -e $log_path;

    open (LOG, ">>", $log_path) or die "couldn't open logfile: $!";
    my $date = `$date_format`;
    chomp ($date);
    print LOG "$card_reader_name $vendor_id:$product_id $date $id".
              " error: $error_message\n";
    close(LOG);

    # Fix the symbolic links
    unless ($status)
    {
        &setupLinks();
    }

    $database->logError($id,$error_message);
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
# Method name: login
#
# Parameters: id        - the users RFID number
#             user_name - the users name
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
    # grab parameters
    my $id = shift;
    my $user_name = shift;
    my $purpose = shift;

    # personalize the login success page
    &parseSuccess($user_name);

    # make sure the log path is correct
    &generatePath();
    # determine whether or not the current log path references an
    # existing file.
    my $status = -e $log_path;

    # write the login to the local logfile
    open (LOG, ">>", $log_path) or die "couldn't open logfile: $!";
    my $date = `$date_format`;
    chomp ($date);

    # if this code is executing, thne the user has successfully
    # logged in and should be added into the list of logged in 
    # users.
    my $time = `date +%s`;
    chomp($time);

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

    # add the id to the list of logged in IDs
    push @logged_in_ids, $id;

    # write the login out to the database
    $database->logAccess($id,1,$purpose);
    $database->login($id);
}

#==============================================================================
#
# Method name: logout
#
# Parameters: user_name - the name of the user being logged out
#             data      - the ID number of the user being logged out.
#
# Returns: void
#
# Description: This method handles logging out the user, including the local
#              and remote recording of their logout.
#
#==============================================================================
sub logout
{
    my $user_name = shift;
    my $id = shift;

    # record that the user has logged out both in the array and the database.
    
    # peel off each ID from the list of currently logged in IDs looking for the
    # one logged out.
    my @tmp;
    my $item;
    do
    {
        $item = pop @logged_in_ids;
        push @tmp, $item;
    }
    while ($item ne $id);

    # drop the logged out ID from tmp
    pop @tmp;

    # put the rest of the still logged in IDs back in logged_in_ids.
    while (scalar(@tmp) > 0)
    {
        push @logged_in_ids, pop @tmp;
    }

    $database->logout($id);
    
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
    print LOG "\n";

    close(LOG);

    # Fix the symbolic links
    unless ($status)
    {
        &setupLinks();
    }

    # log the logout event to the database
    $database->logAccess($id,0);
}
