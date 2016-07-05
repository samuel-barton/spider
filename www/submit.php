<html>
    <head>
        <script type="text/javascript" src="scripts/status.js"></script>
<?php
// write the status to purpose.fifo if it has been submitted
$purpose = $_POST["message"];

// if the purpose is non-empty
if (strlen($purpose) > 0)
{
    // open the fifo, write the message to it, and close
    $purpose_fifo = fopen("purpose.fifo", "w") or die("unable to open file");
    fwrite($purpose_fifo, $purpose);
    fclose($purpose_fifo);
}
?>
    </head>
    <body onload='waitForStatus()'>
        <h2>Submitting...</h2>
    </body>
</html>
