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
echo "Updating aptitude database.";
sudo apt-get update > /dev/null;
if [ $? == "0" ]
then
    echo -n " done.";
fi
echo "Installing libpq-dev.";
sudo apt-get install -y libpq-dev > /dev/null;
if [ $? == "0" ]
then
    echo -n " done.";
fi
echo "Installing lamp-server^.";
sudo apt-get install -y lamp-server^ > /dev/null;
if [ $? == "0" ]
then
    echo -n " done.";
fi
echo "Installing make.";
sudo apt-get install -y make > /dev/null;
if [ $? == "0" ]
then
    echo -n " done.";
fi
echo -n "Installing Perl dependencies.";
echo "Installing DBI.";
sudo cpan install DBI > /dev/null;
if [ $? == "0" ]
then
    echo -n " done.";
fi
echo "Installing DBD::Pg.";
sudo cpan install DBD::Pg > /dev/null;
if [ $? == "0" ]
then
    echo -n " done.";
fi
echo "Installing Parallel::Jobs.";
sudo cpan install Parallel::Jobs > /dev/null;
if [ $? == "0" ]
then
    echo -n " done.";
fi

# -- Apache configuration

# enable headers module for apache
echo -n "Configuring Apache server.";
echo "Enabling headers module.";
sudo a2enmod headers;
if [ $? == "0" ]
then
    echo -n " done.";
fi
sudo service apache2 restart;

# fix the username in the apache config file
cat apache/000-default.conf | sed "s:/home/[a-zA-Z0-9]+/:/home/$(USER)/";

# put the apache config file in the correct directory
sudo cp apache/000-default.conf /etc/apache2/sites-enabled/;

# -- Udev rules configuration

# create the 'input' group, if it doesn't already exist so that the user will
# be able to read from the card reader.
sudo groupadd input;

# put the udev rulse file in the correct directory
sudo cp 100-card-reader.rules /etc/udev/rules.d;

# do the configuration for making Spider.pl a service

# create a user for the spider process
sudo useradd --create-home --system --groups input  spider;
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
