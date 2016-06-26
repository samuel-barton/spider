use v5.14;

#==============================================================================
#
# Name: lsusb.pl
#
# Written by: Samuel Barton
#
# Date: February - March 2014
#
# Project: Log-Based sensors
#
# Description: This file will execute the lsusb command, catch its output, and
#              put relevant data in text files for each type of device. The
#              data from lsusb will be filtered by filter files for each type
#              of device.
#
#==============================================================================

# list of currently connected USB devices (populated by lsusb command)
my @lsusb = `lsusb`;
# List of supported USB devices
my %filter;

# paths of files to put device ids in
my $output_file = "CONNECTED.dev";

# paths of file used as filters for the data in @lsusb
my $filter_path = "SUPPORTED.dev";

# read the list of devices to filter with into a hash keyed by device id
open(filter, "<", $filter_path) or die "Couldn't open file for reading: $!";
for my $line (<filter>)
{
    chomp($line);
    (my $dev_id, my $extension) = 
    ($line =~ /^([a-zA-Z0-9]{4}_[a-zA-Z0-9]{4}) extension: ([a-z.])*/);
    $filter{$dev_id} = $extension;
}
close(filter);

# open the file for output (overwrite everything in the file already)
open(output, ">",
     $output_file) or die "Couldn't open file for output: $!";

# loop through the list of connected devices and print out the device ids to 
# the connected devices file.
for my $line (@lsusb)
{
    # Get the manufacturer and device id
    (my $manufacturer_id, my $product_id) = 
    ($line =~ /([a-zA-Z0-9]{4}):([a-zA-Z0-9]{4})/);

    # if the dev_id is in the list of supported devices, put it in the output
    # file, otherwise ignore it.
    my $dev_id = $manufacturer_id.'_'.$product_id;

    if (my $extension = &isSupported($dev_id))
    {
        say output $dev_id;
    }
}

close(output);

#==============================================================================
#
# Method name: isSupported
#
# Parameters: $dev_id - the manufacturer and product id of the device
#
# Returns: 1 if device in the list of connected devices, 0 otherwise
#
# Description: This method determines if the device referenced by this id is 
#              on the list of supprted devices.
#
#              The method loops through the filter list of devices, and if
#              the device referenced by $dev_id is on the list, the method 
#              closes the filter file and returns 1. If $dev_id is not in the 
#              list of supported devices the method returns 0.
#
#==============================================================================
sub isSupported
{
    my $dev_id = $_[0];

    for my $dev (keys %filter)
    {
        if ($dev_id eq $dev)
        {
            return $filter{$dev_id};
        }
    }

    return 0;
}

