/*=============================================================================
 *
 * Name: welcome.js
 *
 * Created by: Samuel Barton
 *
 * Project: Card Reader
 * 
 * Description: This program will run as a script on the html pages which are 
 *              used to interact with those logging into the system. It will
 *              be responsible for loading different content depending on what
 *              is happening.
 *
 *===========================================================================*/

/*=============================================================================
 *
 * Function: getStatus
 *
 * Parameters: none
 *
 * Returns: void
 * 
 * Description: This function uses AJAX to retrieve the swipe.txt file from the
 *              "server" whose root is at /home/sbarton/card-reader/www. This
 *              file is written to by WebCardReader.pl to alert the page that 
 *              a card swipe has occured. 
 *
 *===========================================================================*/
function getStatus()
{
    var xhttp = new XMLHttpRequest();
    // get the swipe status
    xhttp.open("GET", "swipe.txt", true);
    xhttp.send();

    /* This anonymous function gets called at each ready state change. It does
     * nothing on the first three state changes, but once the ready state 
     * reaches 4 (response received), if the status is 200 (OK) then it will
     * call the funciton to load the password.html page. */
    xhttp.onreadystatechange = function() 
    {
        if (xhttp.readyState == 4 && xhttp.status == 200)
        {
            // the text value returned by the server from swipe.txt (this will
            // be one of "true" or "false"
            var ret_val = xhttp.responseText;

            if (ret_val.includes("true"))
            {
                loadPage();
            }
        }
    };
}

/*=============================================================================
 *
 * Function: loadPage
 *
 * Parameters: none
 *
 * Returns: void
 * 
 * Description: This function loads the password.html page
 *
 *===========================================================================*/
function loadPage()
{
    window.location.assign("password.html");
}

/*=============================================================================
 *
 * Function: waitForSwipe
 *
 * Parameters: none
 *
 * Returns: void
 * 
 * Description: This function calls the getStatus function every second.
 *
 *              NOTE: the crucial thing to remember is that we are dealing with
 *              a language where function-valued parameters are allowed, and 
 *              since the setInterval method is designed to call a function on
 *              a given timeout, we pass it a function valued parameter instead
 *              of invoking the function. This is why we do not put parentheses
 *              after the function name. This is vital in making this call 
 *              work properly, and this took a bit of tie to figure out.
 *
 *===========================================================================*/
function waitForSwipe()
{
    window.setInterval(getStatus, 1000);
}
