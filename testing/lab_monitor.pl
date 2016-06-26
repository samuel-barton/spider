#! /usr/bin/perl

#==============================================================================
#
# Name: lab_monitor.pl
#
# Written by: Daniel Richter
#
# Date: Unknown
#
# Project: Temperature Sensors
#
# Description: 	THIS NEEDS TO BE FILLED IN!!!!!
#
#==============================================================================

use FindBin;
use Tie::File;
$new = 1;
$x = 1;

while( $x ==1)
{
    ($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isdt) = localtime(time);
    $month = $month + 1;
    $year = $year + 1900;
    @data = qx("$FindBin::Bin/temper");
    $i = 0;
    $firstnoserial = 1;
    tie @namesarray, 'Tie::File', "FindBin::Bin/devicenames.conf", recsep=>'\n';
    foreach $item(@data)
    {
	chomp($item);
	$serial = substr( $item, 10, 8);
	if(($firstnoserial == 1) || (serial > 0))
        {
	    $name = 0;
	    if ($serial != 0)
            {
		my $result = grep /"$serial"/, @namesarray;
		my $resultlen = length $result;
		if ( $resultlen > 0)
                {
		    $name= substr($result, 9, 20);
		    chomp($name);
		}
                else
                { 
		    print("New device detected.  Please enter a name for the ".
                          "device.");
		    $newdevname = <STDIN>;
		    chomp ($newdevname);
		    push @namesarray, "$newdevname";
		}
	    }
            else
            {
		$name ="unknown";
	    }
	    open (LOG, 
                  ">>$FindBin::Bin/logs/$month-$mday-$year-$name-templog.log");
	    if ( $hour == 0 && $min == 0 || $new == 1)
            {
		print (LOG "   Date     Time    Temp\n");
		close (LOG);
		unlink ("$FindBin::Bin/logs/current-$name-tempdata.log");
		symlink ("$FindBin::Bin".
                         "/logs/$month-$mday-$year-$name-templog.log", 
                         "$FindBin::Bin/logs/current-$name-tempdata.log");
		open (LOG, 
                  ">>$FindBin::Bin/logs/$month-$mday-$year-$name-templog.log");
	    }
	    $temp = substr($item, 0, 9);
	    print (LOG "$month/$mday/$year,$hour:$min:$sec,$temp\n");
	    close (LOG);
	    $i++;
	    if($serial == 0)
            {
		$firstnoserial = 0;
	    }
	}
        else
        {
	    open (ERROR, ">>$FindBin::Bin/logs/errors.log");
	    print(ERROR "Multiple devices with no serial number detected.  ".
                        "Only first detected device will be logged.\n");
	    close(ERROR);
	    $i++;
	}
    }
    untie @namesarray;
    $i = 0;
    $new = 0;
    $firstnoserial = 0;
    sleep(60);
}
