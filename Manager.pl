use v5.12;
use FindBin;
use Parallel::Jobs;
use DBI;

#==============================================================================
#
# Name: Main-Script.pl
#
# Written by: Samuel Barton
#
# Date: February - May 2014
#
# Project: Manager Scripts
#
# Description:
#
# This script will consist of an infinite loop which does the following each 
# iteration:
#     1. Call script to execute lsusb and place what it returns in a text file.
#         - the text file will be called CONNECTED.dev 
#           (the path will be determined before runtime and saved as a constant 
#           in this script)
#
#     2. Check the list of currently connected devices (CONNECTED.dev) against
#        the hash of devices with scripts running on them. If a device does not
#        have a script running on it, then start one using Parallel::Jobs. Also
#        if a device with a script running on it is no longer connected, then 
#        kill the script.
#
#     3. Query the .csv database and prepare the data to be sent to the
#        parsing and transmit to nagios script.
#
#     4. Push data to the transmit script.
#
#     5. Sleep 60s - the average length of time it takes for this loop to
#        execute to here.
#
#==============================================================================

#    - path to list of currently connected devices.
my $CONNECTED_DEVICES_PATH = "$FindBin::Bin/CONNECTED.dev";
#    - time to sleep at the end of each iteration of the loop
my $SLEEP_TIME = 10;
#    - path to logging subscripts
my $SUBSCRIPT_PATH = "$FindBin::Bin/device_interface_scripts/";
#    - path to logs
my $LOG_PATH = "/logs/";
#    - variable to stop the loop
my $EXIT = 0;
#    - date format used in softlinks management
my $date_format = "%H%M%S";
#    - hash of devices with scripts running on them keyed by devvice id
my %handled_dev;
#    - array of currently connected devices
my @cur_connect_dev;

# This is the "infinite" loop which starts all the logging scripts
until ($EXIT)
{
    # TEMPORARY ---------------------------------------------------------------
    # $EXIT = 1;
    # -------------------------------------------------------------------------

    # Call lsusb
    system("perl lsusb.pl"); # no status yet, figure out if one makes sense.

    # Run subscripts for each connected device which is supported
    # open the file containing the connected devices
    open(connected_devices, "<", 
         $CONNECTED_DEVICES_PATH) or die "couldn't open file: $!";

    # loop through the connected devices file and start subscripts for each
    # supported device currently connected.
    my $i = 0;

    for my $connected_dev (<connected_devices>)
    {
        # remove line termination character to enable equality matching

        # check device against hash of devices with scripts running on them

        # If a device does not have a script running on it
        if (!($handled_dev{$connected_dev}))
        {
            # launch a device interface script for the device with stderr and 
            # stout capture enabled.

            $handled_dev{$connected_dev} = Parallel::Jobs::start_job(
                                          {stderr_capture => 1 |
                                           stdout_capture => 1},
                                       "$FindBin::Bin/$connected_dev.pl");
        }

        # add each connected device to an array for use later
        $cur_connect_dev[$i++] = $connected_dev;
    }

    # kill all scripts whose devices have been disconnected

    # loop through the list of devices with scripts running on them and kill 
    # all scripts whose devices have been disconnected.
    for my $handled_item (keys %handled_dev)
    {
        my $connected = 0;

        for my $cur_item (@cur_connect_dev)
        {
            if ($handled_item eq $cur_item)
            {
                $connected = 1;
            }
        }

        # kill the process (referenced by the pid given by Parallel::Jobs)
        # unless the device which the script is supposed to be handling is 
        # still connected.
        system ("kill $handled_dev{$handled_item}") unless $connected;      
    }

    # Close connection to the list of currently connected devices
    close(connected_devices);

    # Query database for new data

    # Call transmit script

    # Wait <DETERMINE HOW LONG> before running the loop again.
    sleep ($SLEEP_TIME);
}
