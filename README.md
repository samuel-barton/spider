---------------------------DRIVER AND ITERFACE PROGRAMS------------------------

The current implementation of the managmen for the RFID chip reader is done
via two programs.

    read.py - Reads in the data from the card reader directly as binary and 
              decomposes the ID string out of the struct passed in every time
              a swipe occurs.

    CardReader.pl - the program which handles communication with the end user, 
                    and runs the read.py program to get the ID from the card
                    reader.

As it stands right now, the user interacts with a terminal. A login occurs when
a user swipes their card and then enters their password. THey are then 
queried about what they are doing in the lab, and once they enter that info a 
login is logged in the days logfile. When they leave they are asked to badge
out. That causes the logfile to be updated with a logout entry indicating both
the time of their logout, and how long they were in the lab.

----------------------------PLANS FOR CHANGE-----------------------------------

A new version of the program is now being written which will function quite
differently. Instead of interfacing with the user via a terminal, we are going
to have a web interface for the user to interact with. The base functionality
of the program should not change much, but the challenge will be interfacing
with Apache and updating the webpage for the client. 

The new system will work as follows:

  - When the user walks up to the machine a webpage will be displayed asking
    them to swipe their card.

  - Once they swipe their card a welcome message will appear on the screen
    displaying their name and a photograph of them, and they will be prompted
    for a password. They will have three chances to enter their password.

      - If they succeed in entering then they will be asked to enter why they 
        are here. Once they do that their login will be logged and a welcome
        screen will appear on the webpage; also, the door will open for them
        to access the lab. 

      - If they fail three times the page will return to the card swipe 
        request page and the bad login attempt will be logged.

This new program will require some research into how to interface a Perl
program with Apache and other web services. I also need to look into the best
way to make a webpage update on some event via a Perl script.
