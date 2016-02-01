#!/bin/bash
# rsync script

#Validate if root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

PROJECT=$1
CHECKOUT=$2
LOCALPROJECT=$3
DRUPALV=$4
DUSER=$5
DPASS=$6
DBNAME=$7
DBUSER=$8
DBPASS=$9

if [[ -z $PROJECT ||  -z $CHECKOUT || -z $LOCALPROJECT || -z $DRUPALV || -z $DUSER || -z $DPASS || -z $DBNAME || -z $DBUSER || -z $DBPASS ]];

  then
    echo -e "\e[00;31mPlease Provide Project Name\e[00m"
    echo -e "\e[00;31mPlease Provide a folder to check out the project (example: /home/you/websites/customprojects/) as 8th variable\e[00m"
    echo -e "\e[00;31mPlease Provide Site Name inside CheckOut Folder\e[00m"
    echo -e "\e[00;31mPlease Provide DRUPAL Version (e-g 7.23)\e[00m"
    echo -e "\e[00;31mPlease Provide Drupal User\e[00m"
    echo -e "\e[00;31mPlease Provide Drupal PASS\e[00m"
    echo -e "\e[00;31mPlease Provide DB NAME\e[00m"
    echo -e "\e[00;31mPlease Provide DB USER\e[00m"
    echo -e "\e[00;31mPlease Provide DB PASS\e[00m"
    echo -e "\e[00;31mLike ./local-installer-drupal.sh dev.mango.com /var/www/ dev.mango.com 7.31 admin admin007 dev_mango_com [DBUSER] [DBPASS]\e[00m"
    exit
  else
   echo '**********************************************************************************************************************************'
   echo 'Local Installation started'
   echo '**********************************************************************************************************************************'
   echo ' '
fi


#git clone [username]@92.243.15.236:/var/repositories/customprojects/project project.local
if [ ! -d $CHECKOUT$LOCALPROJECT ]; then
  #git clone $USERNAME@92.243.15.236:/var/repositories/$TYPE/$PROJECT $CHECKOUT$LOCALPROJECT
  mkdir $CHECKOUT$LOCALPROJECT
  echo -e "\e[00;32m Directory Created $CHECKOUT$LOCALPROJECT  \e[00m"
  cd $CHECKOUT$LOCALPROJECT
  drush dl drupal-$DRUPALV
  mv drupal-$DRUPALV docroot
  cd $CHECKOUT$LOCALPROJECT"/docroot"
  drush site-install standard --account-name=$DUSER --account-pass=$DPASS --db-url=mysql://$DBUSER:$DBPASS@localhost/$DBNAME

#  chown -R $LOCALUSERGROUP $CHECKOUT$LOCALPROJECT
#  cd $CHECKOUT$LOCALPROJECT
#  git config user.name "$USERNAME"
#  git config user.email "$GITEMAIL"
#  git config color.ui true
#  git config core.filemode false

  echo -e "\e[00;32m Site installed Localy  \e[00m"
  mkdir "sites/all/modules/contrib"
  echo -e "\e[00;32m Contrib Directory Created  \e[00m"
  drush dl admin_menu -y
  drush dis toolbar -y
  drush en admin_menu, admin_menu_toolbar -y
  drush dl masquerade -y
  drush en masquerade -y
  drush dl views -y
  drush en views_ui -y
  drush dl module_filter -y
  drush en module_filter -y
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
  </VirtualHost>" > $APACHEFOLDER/sites-available/$PROJECT.conf
#chown $LOCALUSERGROUP $APACHEFOLDER/nodeex-conf/$PROJECT.conf
echo -e "\e[00;32mAdded local vhost conf to $APACHEFOLDER/sites-available/$PROJECT.conf \e[00m"

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

#Doc output
echo "Type in url in browser:http://$LOCALPROJECT"
