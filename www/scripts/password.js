/*=============================================================================
 *
 * Name: password.js
 *
 * Created by: Samuel Barton
 *
 * Project: IMT / card reader (Spider)
 *
 * Description: This script will handle retriving the password and passing it 
 *              back to WebCardReader.pl
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
 *              file is written to by WebCardReader.pl to alert the page of 
 *              the password authentication status. 
 *
 *===========================================================================*/
function getStatus()
{
    var xhttp = new XMLHttpRequest();
    // get the swipe status
    xhttp.open("GET", "status.txt", true);
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
                loadPage("status.php");
            }
            else if (ret_val.includes("false"))
            {
                loadPage("fail.php");
            }
            else 
            {
                loadPage("password.php");
            }
        }
    };
}

/*=============================================================================
 *
 * Function: loadPage
 *
 * Parameters: page
 *
 * Returns: void
 * 
 * Description: This function loads the requested page
 *
 *===========================================================================*/
function loadPage(page)
{
    window.location.assign(page);
}


/*=============================================================================
 *
 * Function: waitForStatus
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
function waitForStatus()
{
    window.setInterval(getStatus, 1000);
}
