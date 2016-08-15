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
# Project: Spider
#
# Description: This program reads in card numbers from the swipe card reader,
#              and writes them to a pipe which is read from by Spider.pl
#
#              The fifo written to is defined by command line argument, but if
#              no argument is present it is written to the fifo read by 
#              Spider.pl.
#
#==============================================================================

# These key codes came from /usr/include/linux/input-event-codes.h
KEY_1 = 2
KEY_2 = 3
KEY_3 = 4
KEY_4 = 5
KEY_5 = 6
KEY_6 = 7
KEY_7 = 8
KEY_8 = 9
KEY_9 = 10
KEY_0 = 11
KEY_MINUS = 12
KEY_EQUAL = 13
KEY_Q = 16
KEY_W = 17
KEY_E = 18
KEY_R = 19
KEY_T = 20
KEY_Y = 21
KEY_U = 22
KEY_I = 23
KEY_O = 24
KEY_P = 25
KEY_ENTER = 28
KEY_A = 30
KEY_S = 31
KEY_D = 32
KEY_F = 33
KEY_G = 34
KEY_H = 35
KEY_J = 36
KEY_K = 37
KEY_L = 38
KEY_SEMICOLON = 39
KEY_LEFTSHIFT = 42 
KEY_BACKSLASH = 43
KEY_SLASH = 53
KEY_Z = 44
KEY_X = 45
KEY_C = 46
KEY_V = 47
KEY_B = 48
KEY_N = 49
KEY_M = 50
KEY_COMMA = 51
KEY_DOT = 52

code_to_key = {};

# Python dictionaries cannot have variables as keys... so we'll use this lame
# workaround.
code_to_key[KEY_1] = str(1)
code_to_key[KEY_2] = str(2)
code_to_key[KEY_3] = str(3)
code_to_key[KEY_4] = str(4)
code_to_key[KEY_5] = str(5)
code_to_key[KEY_6] = str(6)
code_to_key[KEY_7] = str(7)
code_to_key[KEY_8] = str(8)
code_to_key[KEY_9] = str(9)
code_to_key[KEY_0] = str(0)
code_to_key[KEY_MINUS] = '-'
code_to_key[KEY_EQUAL] = '='
code_to_key[KEY_Q] = 'Q'
code_to_key[KEY_W] = 'W'
code_to_key[KEY_E] = 'E'
code_to_key[KEY_R] = 'R'
code_to_key[KEY_T] = 'T'
code_to_key[KEY_Y] = 'Y'
code_to_key[KEY_U] = 'U'
code_to_key[KEY_I] = 'I'
code_to_key[KEY_O] = 'O'
code_to_key[KEY_P] = 'P'
code_to_key[KEY_A] = 'A'
code_to_key[KEY_S] = 'S'
code_to_key[KEY_D] = 'D'
code_to_key[KEY_F] = 'F'
code_to_key[KEY_G] = 'G'
code_to_key[KEY_H] = 'H'
code_to_key[KEY_J] = 'J'
code_to_key[KEY_K] = 'K'
code_to_key[KEY_L] = 'L'
code_to_key[KEY_SEMICOLON] = ';'
code_to_key[KEY_Z] = 'Z'
code_to_key[KEY_X] = 'X'
code_to_key[KEY_C] = 'C'
code_to_key[KEY_V] = 'V'
code_to_key[KEY_B] = 'B'
code_to_key[KEY_N] = 'N'
code_to_key[KEY_M] = 'M'
code_to_key[KEY_COMMA] = ','
code_to_key[KEY_DOT] = '.'


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

# the path to the card reader. Allow for either the swipe card reader or the 
# RFID card reader.
card_reader_path = ""
if (len(sys.argv) > 1 and sys.argv[1] == "--rfid"):
    card_reader_path = "/dev/input/by-id/usb-13ba_Barcode_Reader-event-kbd"
elif (len(sys.argv) > 1 and sys.argv[1] == "--swipe"):
    card_reader_path = "/dev/input/by-id/usb-Mag-Tek_USB_Swipe_Reader-event-kbd"

# set the path for the fifo.
fifo_path = "card-id-num.fifo"

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

current_id_num = ""
shifted = False
while event:
    (tv_sec, tv_usec, type, code, value) = struct.unpack(FORMAT, event)

    # value = 1 -> that a value has been entered.
    # we only care about events when value == 1
    if (value == 1):
        # if the code is the starting delimitor, clear out the card number 
        # string
        if (code == KEY_SEMICOLON or 
           (shifted and (code == KEY_5 or code == KEY_EQUAL))):
            current_id_num = ""
            shifted = False
        # The keyboard event for the "shift" key in regards to a card reader may
        # seem odd, but this is how one gets keys like "?" and "%". We set a
        # flag so that we can check for either "%", a starting delimitor, or 
        # "?", an ending delimitor.
        elif (code == KEY_LEFTSHIFT):
            shifted = True
        # the "?" key is the end delimitor for swipe style card readers, and 
        # so when it is found the ID gets written to the fifo, and everything 
        # is reset to read in another ID. The "\n" key is the end delimitor for
        # the RFID card reader.
        elif ((code == KEY_SLASH and shifted) or code == KEY_ENTER):
            fifo = open(fifo_path, 'w')
            fifo.write(current_id_num + "\n")
            fifo.close()
            current_id_num = ''
	    shifted = False
        else:
            current_id_num += translate(code)

    # read in the next event, and go back to the top of the loop
    event = card_reader.read(EVENT_SIZE)

# note, this is not a part of the while loop, python uses indentation instead
# of brackets in scoping.
card_reader.close()
