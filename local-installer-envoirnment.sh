#!/bin/bash
# rsync script

#Validate if root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

CHECKOUT=$1
LOCALPROJECT=$2
DBNAME=$3
DBUSER=$4
DBPASS=$5

if [[ -z $CHECKOUT || -z $LOCALPROJECT || -z $DBNAME || -z $DBUSER || -z $DBPASS ]];

  then
    echo -e "\e[00;31mPlease Provide a folder to check out the project (example: /home/you/websites/customprojects/) as 8th variable\e[00m"
    echo -e "\e[00;31mPlease Provide Site Name inside CheckOut Folder\e[00m"
    echo -e "\e[00;31mPlease Provide DB NAME\e[00m"
    echo -e "\e[00;31mPlease Provide DB USER\e[00m"
    echo -e "\e[00;31mPlease Provide DB PASS\e[00m"
    echo -e "\e[00;31mLike ./local-installer-drupal.sh /var/www/ dev.mango.com [DATABASE_NAME] [DBUSER] [DBPASS]\e[00m"
    exit
  else
   echo '**********************************************************************************************************************************'
   echo 'Local Installation started'
   echo '**********************************************************************************************************************************'
   echo ' '
fi


if [ ! -d $CHECKOUT$LOCALPROJECT ]; then
  mkdir $CHECKOUT$LOCALPROJECT
  echo -e "\e[00;32m Directory Created $CHECKOUT$LOCALPROJECT  \e[00m"
  cd $CHECKOUT$LOCALPROJECT
  mkdir docroot
  echo -e "\e[00;32m Docroot Directory Created $CHECKOUT$LOCALPROJECT"/docroot"  \e[00m"
  cd $CHECKOUT$LOCALPROJECT"/docroot"
  echo -e "\e[00;32m Site installed Localy  \e[00m"
else
  echo -e "\e[00;31m $CHECKOUT$LOCALPROJECT exists, skipping checkout creation\e[00m"
fi

#Variables
APACHEFOLDER='/etc/apache2'

#Create local conf file
mkdir -p $APACHEFOLDER/nodeex-conf
echo "
  <VirtualHost *:80>
    ServerName $LOCALPROJECT
    ServerAlias *.$LOCALPROJECT
    DocumentRoot $CHECKOUT$LOCALPROJECT/docroot
    <Directory $CHECKOUT$LOCALPROJECT/docroot>
      Options Indexes FollowSymLinks MultiViews
      AllowOverride All
      Order allow,deny
      allow from all
    </Directory>
  </VirtualHost>" > $APACHEFOLDER/sites-available/$LOCALPROJECT.conf
echo -e "\e[00;32mAdded local vhost conf to $APACHEFOLDER/sites-available/$LOCALPROJECT.conf \e[00m"

#Create apachehosts file


#sudo a2ensite project.local
sudo a2ensite $LOCALPROJECT
echo -e "\e[00;32m Add site to apache \e[00m"


#sudo service apache2 restart
sudo service apache2 restart
echo -e "\e[00;32m Reload apache \e[00m"

#Create entry in /etc/hosts

HOSTS=`grep -o $LOCALPROJECT /etc/hosts | head -n1`
if [ "$HOSTS" == "$LOCALPROJECT" ]; then
  echo -e "\e[00;31mHosts file already contains entry for $LOCALPROJECT skipping creation\e[00m"
else
  echo "127.0.0.1 $LOCALPROJECT" >> /etc/hosts
  echo -e "\e[00;32m Entry $LOCALPROJECT added to hosts file \e[00m"
fi

#Creating DATABASE
MYSQL=`which mysql`
  
Q1="CREATE DATABASE IF NOT EXISTS $DBNAME;"
SQL="${Q1}"
  
$MYSQL -u $DBUSER -p$DBPASS -e "$SQL"
echo "$DBNAME Database Created"

#Doc output
echo "Type in url in browser:http://$LOCALPROJECT"
