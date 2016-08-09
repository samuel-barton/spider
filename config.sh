#! /bin/bash

#==============================================================================
#
# File name: config.sh
#
# Created by: Samuel Barton
#
# Project: Spider (IMT card reader)
#
# Date: Summer 2016
#
# Description: This script will handle deploying project spider on some system.
#
#==============================================================================

# install dependencies
sudo apt-get update;
sudo apt-get install libpq-dev lamp-server^;
sudo cpan install DBI;
sudo cpan install DBD::Pg;
sudo cpan install Parallel::Jobs;

# enable headers module for apache
sudo a2enmod headers;
sudo service apache2 restart;

# fix the username in the apache config file
cat apache/000-default.conf | sed "s:/home/[a-zA-Z0-9]+/:/home/$(USER)/";
# put the apache config file in the correct directory
sudo cp apache/000-default.conf /etc/apache2/sites-enabled/;

