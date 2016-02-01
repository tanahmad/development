#!/bin/bash
# rsync script

#Validate if root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

CHECKOUT=$1
LOCALPROJECT=$2
REPOSITORYFOLDER=$3
REPOSITORYNAME=$4

if [[ -z $CHECKOUT || -z $LOCALPROJECT || -z $REPOSITORYFOLDER || -z $REPOSITORYNAME ]];

  then
    echo -e "\e[00;31mPlease Provide a folder to check out the project (example: /var/www/)\e[00m"
    echo -e "\e[00;31mPlease Provide LOCALPROJECTFOLDER inside CHECKOUT \e[00m"
    echo -e "\e[00;31mPlease Provide REPOSITORYFOLDER name.\e[00m"
    echo -e "\e[00;31mPlease Provide REPOSITORYNAME name.\e[00m"
    exit
  else
   echo '**********************************************************************************************************************************'
   echo 'Local Installation started'
   echo '**********************************************************************************************************************************'
   echo ' '
fi

#Validation
case "$CHECKOUT" in
*/)
    ;;
*)
    echo -e "\e[00;31m CHECKOUT must end with a slash \e[00m"
    exit
    ;;
esac

case "$REPOSITORYFOLDER" in
*/)
    ;;
*)
    echo -e "\e[00;31m REPOSITORYFOLDER must end with a slash \e[00m"
    exit
    ;;
esac


if [ ! -d $CHECKOUT$LOCALPROJECT  ]; then
  echo -e "\e[00;31mLocation $CHECKOUT$LOCALPROJECT does noet exists \e[00m"
  exit
fi

#Inititaing Repository
cd $CHECKOUT$LOCALPROJECT 
git init
git add .
git commit -m"First Commit"
echo "\e[00;31mGit initialized. \e[00m"

#create a bare repository
echo -e "\e[00;31mCreating a bare repository.\e[00m"
mkdir -p $REPOSITORYFOLDER$REPOSITORYNAME.git
echo -e "\e[00;31m$REPOSITORYNAME.git created in $REPOSITORYFOLDER \e[00m"
cd $REPOSITORYFOLDER$REPOSITORYNAME.git
git init --bare
echo -e  "\e[00;31m Bare initialized. \e[00m"
cd $CHECKOUT$LOCALPROJECT
echo -e "\e[00;31m Now at $CHECKOUT$LOCALPROJECT to push. \e[00m"
git push $REPOSITORYFOLDER$REPOSITORYNAME.git master

# Configuring “hub” repository as a remote for the live repository. 
HOSTS=`grep -o $REPOSITORYNAME.git $CHECKOUT$LOCALPROJECT/.git/config | head -n1`
if [ "$HOSTS" == "$REPOSITORYNAME.git" ]; then
  echo -e "\e[00;31mConfig file already contains entry for $REPOSITORYNAME skipping creation\e[00m"
else
  echo '
[remote "hub"]
  url = '$REPOSITORYFOLDER$REPOSITORYNAME.git'
  fetch = +refs/heads/*:refs/remotes/hub/*
  ' >> $CHECKOUT$LOCALPROJECT/.git/config
  echo -e "\e[00;32m Entries added to config file \e[00m"
fi

#Create hook to pull from hub repository into the live repo.

echo "#!/bin/sh

echo
echo '**** Pulling changes into Live [Hubs post-update hook]'
echo

cd $CHECKOUT$LOCALPROJECT || exit
unset GIT_DIR
git pull hub master

exec git-update-server-info" > $REPOSITORYFOLDER$REPOSITORYNAME.git/hooks/post-update

chmod +x $REPOSITORYFOLDER$REPOSITORYNAME.git/hooks/post-update



