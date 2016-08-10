#! /bin/bash

#------------------------------------------------------------------------------
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
#------------------------------------------------------------------------------

# install dependencies
echo "Part one: dependencies"
sudo apt-get update;
sudo apt-get install -y libpq-dev lamp-server^ make;
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

# do the configuration for making Spider.pl a service

# create a user for the spider process
sudo useradd --create-home --system spider;
# put the service file in the upstart service directory
sudo cp spider.conf /etc/init;

# ask the user if they would like to reboot the machine, which will apply the
# changes made thus far.
echo "To finish the configuration, the machine must restart."
echo -n "Do you want to restart now [y/n]: "
# get the users decision
decision=${read};

if [ $decision == "y" || $decision == "" ]
then
    sudo reboot
fi
