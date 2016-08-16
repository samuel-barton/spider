<html>
    <head>
        <script type="text/javascript" src="scripts/password.js"></script>
<?php
// Get the password (if it has been submitted)
$password = $_POST["password"];
// if the password has been submitted
if (strlen($password) > 0)
{
    // open the fifo, write the password to it, and close
    $password_fifo = fopen("password.fifo", "w") or die("unable to open file");
    fwrite($password_fifo, $password);
    fclose($password_fifo);
}
?>
    </head>
    <body onload='waitForStatus()'>
        <h1>Authenticating...</h1>
    </body>
</html>
