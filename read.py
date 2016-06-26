#!/usr//bin/env python

import struct
import time
import sys
import os
import stat

#==============================================================================
#
# Name: read.py
#
# Written by: Samuel Barton
#
# note: the basis for reading in the data from the card reader came from: 
#       http://stackoverflow.com/questions/5060710/format-of-dev-input-event
#
# Date: development - April 2014
#       commenting and finishing modifications: May 2014
#
# Project: RF Card Reader
#
# Description: This program reads in card numbers from the RF card reader, and
#              writes them to a pipe which is read from by smartCardReader.pl
#
#              The fifo written to is defined by command line argument, but if
#              no argument is present it is written to the fifo read by 
#              smartCardReader.pl.
#
#==============================================================================

# the codes
# KEY_1 = 2
# KEY_2 = 3
# KEY_3 = 4
# KEY_4 = 5
# KEY_5 = 6
# KEY_6 = 7
# KEY_7 = 8
# KEY_8 = 9
# KEY_9 = 10
# KEY_0 = 11

code_to_key = {
    2 : str(1),
    3 : str(2),
    4 : str(3),
    5 : str(4),
    6 : str(5),
    7 : str(6),
    8 : str(7),
    9 : str(8),
    10 : str(9),
    11 : str(0)
}


#==============================================================================
#
# Function name: translate
#
# Parameters: code - the code value from the card reader
#
# Returns: String - the key pressed
#
# Description: This function translates the code value to the value of the key
#              presses, this is used to make it so the value passed over the 
#              FIFO is the card number, and not the list of codes.
#
#==============================================================================
def translate(code):
    return code_to_key.get(code, 'None')

# the path to the card reader
card_reader_path = "/dev/input/by-id/usb-13ba_Barcode_Reader-event-kbd"
#card_reader_path ="/dev/input/event16";

# the number of digits in the card id number
num_digits = 10

# the name of the FIFO being used to send the card number to the Event Handler
fifo_path = (sys.argv[1] if (len(sys.argv) > 1) else 'card-id-num.fifo')

# setup the FIFO
# if the FIFO referenced by fifo_path is not a FIFO, delete the file and create
# a new FIFO.
if (os.path.exists(fifo_path) and 
   (not stat.S_ISFIFO(os.stat(fifo_path).st_mode))):
    os.remove(fifo_path)
    os.mkfifo(fifo_path)

# if the FIFO referenced by fifo_path does not exist, create a new FIFO.
if (not os.path.exists(fifo_path)):
    os.mkfifo(fifo_path)

# The format of the structure sent by the card reader is
# long int, long int, unsigned short, unsigned short, unsigned int
FORMAT = 'llHHI'
EVENT_SIZE = struct.calcsize(FORMAT)

# open file in binary mode and read in the first struct
card_reader = open(card_reader_path, "rb")
event = card_reader.read(EVENT_SIZE)

# read in the ten digits of the card id number, concatenating them onto a
# String. Once all ten digits have been read in write the sttring to the pipe
# and restart
current_id_num = ""
num_vals_received = 0
while event:
    (tv_sec, tv_usec, type, code, value) = struct.unpack(FORMAT, event)

    # The value of code should only be recorded when 'value' is 1.
    # read in the ten digits of the id number
    if num_vals_received < 10 and code < 28 and value == 1:
        curr_val = translate(code)
        current_id_num += str(curr_val)
        num_vals_received += 1

    # once the ten digits have been read in, write the card number to the fifo
    # and reset the variables for the next card number.
    elif num_vals_received == 10 and code == 28:
        fifo = open(fifo_path, 'w')
        fifo.write(current_id_num + "\n")
        fifo.close()
        num_vals_received = 0
        current_id_num = ''

    # read in the next event, and go back to the top of the loop
    event = card_reader.read(EVENT_SIZE)

# note, this is not a part of the while loop, python uses indentation instead
# of brackets in scoping.
card_reader.close()
