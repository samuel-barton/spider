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
echo -n "Updating aptitude database.";
sudo apt-get update > /dev/null;
if [ $? == "0" ]
then
    echo " done.";
fi
echo -n "Installing libpq-dev.";
sudo apt-get install -y libpq-dev > /dev/null;
if [ $? == "0" ]
then
    echo " done.";
fi
echo -n "Installing Apache.";
sudo apt-get install -y apache2 > /dev/null;
if [ $? == "0" ]
then
    echo " done.";
fi
echo -n "Installing PHP 5.";
sudo apt-get install -y php2 > /dev/null;
if [ $? == "0" ]
then
    echo " done.";
fi
echo -n "Installing make.";
sudo apt-get install -y make > /dev/null;
if [ $? == "0" ]
then
    echo " done.";
fi
echo "Installing Perl dependencies.";
echo -n "Installing DBI.";
sudo cpan install DBI > /dev/null;
if [ $? == "0" ]
then
    echo " done.";
fi
echo -n "Installing DBD::Pg.";
sudo cpan install DBD::Pg > /dev/null;
if [ $? == "0" ]
then
    echo " done.";
fi
echo -n "Installing Parallel::Jobs.";
sudo cpan install Parallel::Jobs > /dev/null;
if [ $? == "0" ]
then
    echo " done.";
fi

# -- Apache configuration

# enable headers module for apache
echo "Configuring Apache server.";
echo -n "Enabling headers module.";
sudo a2enmod headers;
if [ $? == "0" ]
then
    echo " done.";
fi
sudo service apache2 restart;

# fix the username in the apache config file
cat apache/spider.conf | sed "s:/home/[a-zA-Z0-9]+/:/home/$(USER)/" > tmp;
mv tmp apache/spider.conf;

# put the apache config file in the correct directory
sudo cp apache/spider.conf /etc/apache2/sites-enabled/;

# -- Udev rules configuration

# create the 'input' group, if it doesn't already exist so that the user will
# be able to read from the card reader.
sudo groupadd input;

# put the udev rulse file in the correct directory
sudo cp 100-card-reader.rules /etc/udev/rules.d;

# do the configuration for making Spider.pl a service

# get the path to where perl puts its libraries on this machine.
perl_path=$(perl -e 'print "@INC"' | awk '{print $1;}');
echo  -n "installing Perl libraries Persist.pm Hex.pm GenHTML.pm.";
sudo cp GenHTML.pm Hex.pm Persist.pm $perl_path;
if [ $? == "0" ]
then
    echo " done.";
fi

# Spider.pl will be deployed to /usr/share/spider
sudo mkdir /usr/share/spider;
echo  -n "Installing Spider.pl."
sudo cp Spider.pl /usr/share/spider;
if [ $? == "0" ]
then
    echo " done.";
fi

# add the current user to the input group.
sudo usermod -aG input $USER;

# ask the user if they would like to reboot the machine, which will apply the
# changes made thus far.
echo "To finish the configuration, the machine must restart."
echo -n "Do you want to restart now [y/n]: "
# get the users decision
decision=$(read);

if [ $decision == "y" || $decision == "" ]
then
    sudo reboot
fi
