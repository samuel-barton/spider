#!/usr/bin/perl

use v5.14;

while (1)
{
    open (result, ">>", "result.txt") or die;

    print result ".";
    sleep (1);

    close(result);
}
