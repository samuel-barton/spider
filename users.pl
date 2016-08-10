#! /usr/bin/perl

#==============================================================================
#
# File name: users.pl
#
# Created by: Samuel Barton
#
# Project: Spider (IMT card reader)
#
# Date: Summer 2016
#
# Description: This script acts as a maintenance script making it easy to add
#              users to the databse.
#==============================================================================

use v5.14;
use Persist;

# Get the relavent information from the user
say "Add a user to the database.";
print "ID: ";
my $id = <stdin>;
print "name: ";
my $name = <stdin>;
print "password: ";
my $password = <stdin>;
print "photo path: ";
my $photo_path = <stdin>;

# trim newlines from all input parameters
chomp($id);
chomp($name);
chomp($password);
chomp($photo_path);

# create a Persist object
my $database = Persist->spawn();
# add the new user to the database, or print an error message and terminate the
# program.
$database->addUser($id,
                   $name,
                   $password,
                   $photo_path) or die "Couldn't add user.";

# if we make it here, then the user was successfully added to the database
say "User added to database.";
