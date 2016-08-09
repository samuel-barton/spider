#!/usr/bin/env perl

use v5.14;
use Fcntl;
use POSIX;
use Parallel::Jobs;
use FindBin;
use IO::Select;
use Persist;
use GenHTML;
use Hex;

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
# Description: This program handles the human interface for a RFID card reader.
#              It provides a web-based user interface for the user to enter
#              their credentials and purpose for entering the facility. 
#              Persistance is handled through a database, with local textfile
#              backup for the access log.
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
#              When the program starts, it reads in the list of currently
#              logged in users (from the last time the program ran). This info
#              is stored in a PostgreSQL database on a remote machine.
#
#              Login: - card number is recognized
#
#              The user is asked for their credentials, and is given  three 
#              chaces to enter  his or her password. He or she is then required
#              to enter a message describing the purpose of his or her visit
#              to the workspace. Upon entering a purpose to their visit, the 
#              login is logged and the user is added to the list of currently 
#              logged in users.
#
#              Logout:
#
#              The users ID is removed from the list of currently logged in
#              IDs, their logout is recorded on the local and database access
#              log, and a message is displayed on the web-interface aletring
#              them that they have been successfully logged out.
#
#              The format for the date and time portion of the log entry will
#              look like this: <month> <day> <year> <hr 0..23> <min> <seconds>
#              This is the command used to get the date in that format:
#                  date +%b\ %d\ %Y\ %H:%M:%S
#
#              At the end of each iteratoin of the main loop, whether a login
#              or a logout occurred, any card numbers received after the first
#              one are discarded.
#
#              The program will do the following things
#              - ask the user to swipe their card
#              - ask for a password
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
#
#              The log will look like so (for a logout)
#              <log info> <date> logout <username> 
#
#              FindBin::bin is used to find the directory in which this program
#              is currently running.
#
#              This program depends on the Persist.pm object for connectivity
#              to the database, and on the GenHtml.pl file for customizing the 
#              webpages displayed to the user.
#
#===============================================================================
# - Sentinel for the control loop
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
my $fifo_path = "$FindBin::Bin/card-id-num.fifo";
# - The path to the named pipe used to get the users password from the web UI
my $password_fifo_path = "$FindBin::Bin/www/password.fifo";
# - The path to the named pipe used to get the users purpose from the web UI
my $purpose_fifo_path = "$FindBin::Bin/www/purpose.fifo";
# - The array of currently logged in users
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

# Create two named pipes, password.fifo and purpose.fifo in the Apache 
# DocumentRoot for retrieving informaiton submitted in the web-forms.
&createFifo($password_fifo_path);
&createFifo($purpose_fifo_path);

# log users in and out of the system as they swipe their cards and enter their
# credentials
until ($stop)
{
    $restart = 0;

    # Keep the welcome webpage visible until recognized card is swiped.
    &setStatus("false");

    # Once data is received, store it in $id.
    open(fifo, "<", $fifo_path);
    my $id = <fifo>;
    chomp($id);

    # find out if the card number is recognized.
    (my $user_name, my $real_password, my $photo) = &isAuthorizedUser($id);
    # write the photo of the user to the www/img directory.
    Hex::hexToFile("www/img/$user_name.jpg", $photo);

    # If the user is currently logged in, log them out of the system, display a
    # message on the web UI alerting them that they have been logged out for 3
    # seconds, and then reload the welcome page.
    if (&loggedIn($id))
    {
        # update the datahbase to reflect the logout
        &logout($user_name, $id);

        # trigger loading logout.php by welcome.js
        &setStatus("logout");
        # customize the logout.php page
        GenHTML::parseLogout($user_name);
        sleep (3);
    }
    # if the user is not logged in and the id is recognized, log them into the
    # system.
    elsif ($user_name ne $UNAUTHORIZED_CARD)
    {        
        my $count = 0;
        my $password = "";

        # Customize the password.php page
        GenHTML::parsePassword($user_name);
        # trigger loading the password.php page by welcome.js
        &setStatus("login");

        # give the user three chances to enter their password.
        until (($password eq $real_password) or $count == 3)
        {
            # open the password pipe and read its value (this will block till
            # something is written to the pipe). The password.fifo pipe is 
            # written to by auth.php.
            open (password_fifo, "<", $password_fifo_path) or 
            die "couldn't open file: $!";

            $password = <password_fifo>;
            close(password_fifo);
            chomp($password);

            # trigger a reload of password.php by password.js
            &setStatus("continue");
            $count++;
        }
      
        # If the password isn't correct at this point the user has exhausted 
        # their chances and this session will exit after the failed attempt is 
        # logged. Also the welcome page will be reloaded.
        if ($real_password ne $password)
        {
            # Customize the fail.php page
            GenHTML::parseFail($user_name);

            # trigger a load of fail.php by passwrod.js
            &setStatus("false");

            # log the error and restart the whole process
            &logError($id, "password does not match.");
            $restart = 1;
        }

        # If we make it here, the user has succeeded in entering his or her 
        # password.
        unless ($restart)
        {
            # Customize the status.php page.
            GenHTML::parseStatus($user_name);

            # triger a load of status.php by password.js
            &setStatus("true");

            # open the purpose pipe and read its value (this will block until
            # something is written to the pipe). The pipe is written to by 
            # submit.php.
            open(purpose_fifo, "<", $purpose_fifo_path) or 
            die "couldn't open file: $!";

            my $purpose = <purpose_fifo>;
            close(purpose_fifo);
            chomp($purpose);

            # trigger a reload of status.php if the user enters no purpose.
            &setStatus("continue");

            # keep asking the user to enter their purpse until they
            # enter data.
            until (length($purpose) > 0)
            {
                open(purpose_fifo, "<", $purpose_fifo_path) or 
                die "couldn't open file: $!";
                $purpose = <purpose_fifo>;
                close(purpose_fifo);
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

    # if the database had nothing on this user, then return an array of three
    # empty strings to indicate that each field (username,password,photo) had
    # no information.
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
# Parameters: id            - the user's ID
#             error_message - a conscise description of the error
#
# Returns: void
#
# Description: This method enables easy logging of error messages both to the 
#              local log file and to the database.
#
#==============================================================================
sub logError
{
    # get the arguments
    my $id = shift;
    my $error_message = shift;

    # make sure the log path is correct
    &generatePath();
    my $status = -e $log_path;

    # log the error using the local textfile-based system
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

    # log the error to the database 
    $database->logError($id,$error_message);
}

#==============================================================================
#
# Method name: setupLinks
#
# Parameters: none
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
    my $status = shift;

    open(STATUS, ">", "$FindBin::Bin/www/status.txt") or 
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
    my $fifo_path = shift;

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
# Description: This method logs the user into the system, recrding the login to
#              both the database and the local textfile-based system.
#
#==============================================================================
sub login
{
    # grab parameters
    my $id = shift;
    my $user_name = shift;
    my $purpose = shift;

    # personalize the login success page
    GenHTML::parseSuccess($user_name);

    # make sure the log path is correct
    &generatePath();
    # determine whether or not the current log path references an
    # existing file.
    my $status = -e $log_path;

    # write the login to the local logfile
    open (LOG, ">>", $log_path) or die "couldn't open logfile: $!";
    my $date = `$date_format`;
    chomp ($date);

    # The name of the card-reader, and the vendor and product ids
    # need to be able to change with different devices.
    print LOG "$card_reader_name $vendor_id:$product_id $date".
          " login '$user_name' $purpose\n";
    close(LOG);

    # fix the symbolic links
    unless ($status)
    {
        &setupLinks();
    }

    # add the id to the list of logged in IDs
    push @logged_in_ids, $id;
    # update the databases list of logged in IDs
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
    # grab parameters
    my $user_name = shift;
    my $id = shift;

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

    # update the database to reflect the user's logout
    $database->logout($id);
}
