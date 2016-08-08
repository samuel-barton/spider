/*=============================================================================
 *
 * Name: success.js
 *
 * Created by: Samuel Barton
 *
 * Project: IMT / card reader (Spider)
 *
 * Description: This script does one thing, waits five seconds, and then loads
 *              the welcome page.
 *
 *===========================================================================*/

function loadPage()
{
    window.location.assign("welcome.html");
}

function pauseThenLoad()
{
    window.setTimeout(loadPage, 5000);
}
