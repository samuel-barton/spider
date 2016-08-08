Project Spider
-------------------------------------------------------------------------------
RFID authentication system.

Spider consists of three pieces:

    Driver software     to handle connecting to and reading from the RFID 
                        card reader.

    Interface software  to handle interacting with an end user who will use the
                        software to login/logout of some location.

    Storage software    to handle persistance of the access log, authorized 
                        user list, and credential information.

The structure of the code which makes up this porject is much less monolithic 
than the above breakdown implies. Each of these pieces coexists within the 
collection of Perl, Python, PHP, Javascript, and html that makes up this 
project. To make the complexity of this project less overbearing, a short
description of each peice of code which makes up this project is provided.

    read.py             Interfaces with the card reader, retrieves the binary
                        data from the card reader, extracts the card number, 
                        and writes that to a named pipe (card-id-num.fifo).

    WebCardReader.pl    Daemon. Main program which launches read.py and calls
                        upon functions in GenHtml.pl. Handles authentication
                        and logging. Built for the web-based UI.

    TextCardReader.pl   Text-based version of WebCardReader.pl. Has all the 
                        same functionality, but uses a terminal for interacting
                        with the end user.

    GenHtml.pl          Personalizes html (actually PHP) files used for the 
                        web UI. Writes to fail.php, logout.php, password.php
                        status.php, and success.php.

    welcome.js          Waits for swipe of authenticated card, alerted by 
                        WebCardReader.pl, then loads password.php.

    password.js         Waits for authentication of submitted password, 
                        authentication is handled by WebCardReader.pl, and 
                        loads status.php on a correct password. On a failed 
                        password it either reloads password.php or fail.php
                        depending on status from WebCardReader.pl. 

    status.js           Waits for acceptance of entered reason for logging in
                        and then loads success.php if the user entered a non-
                        empty reason. Otherwise status.php is loaded again.

    util.js             Contains miscelanious utility functions.

    welcome.html        Simple html page which calls welcome.js on load and 
                        asks the user to swipe their card.

    auth.php            loaded on password submit by password.php, posts the
                        submitted password to password.fifo for 
                        WebCardReader.pl to authenticate.

    password.php        Simple page with a form for the user to enter their 
                        password wihch calls auth.php on submission.

    status.php          Simple page with a form for the user to enter their 
                        reason for logging in. Calls submit.php on form 
                        submission.

    submit.php          Waits for the response from WebCardReader.pl to be 
                        sure that the reason for logging in was accepted. If
                        it was, then success.php is loaded, otherwise 
                        status.php is loaded again.

    success.php         Displays a message to the user alerting them that they
                        have been successfully logged in. On page load util.js
                        is called upon to load welcome.html in five seconds.

    fail.php            Loaded by auth.php upon a 'fail' status from 
                        WebCardReader.pl. Displays a message indicating login
                        failure due to incorrect password entry. On page load
                        util.js is called upon to load welcome.html in five
                        seconds.

    logout.php          Displays a message to the user alerting them that they
                        have been logged out of the system successfully. On 
                        page load calls util.js to load welcome.html in five
                        seconds. Loaded by welcome.js upon 'logout' status from
                        WebCardReader.pl.

In addition to the number of files which make up this project, some of its 
complexity is derived from the Apache server which must be running in order
for the web UI to work at all. The key things to do when configuring the apache
server for this project are to disable all caching in the virtual-host file, 
and set the DocumentRoot property to '/home/<username>/card-reader/www'.
