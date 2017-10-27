#!/bin/bash

# Reference: https://gordonlesti.com/change-default-users-on-raspberry-pi/

setup_user(){
  # first add new user
  sudo adduser $1

  # now add to sudo group
  sudo adduser $1 sudo
}

setup_sshkey(){
  # path to .ssh dir
  local ssh_dir="/home/${1}/.ssh"

  # setup .ssh dir in $HOME
  sudo mkdir $ssh_dir

  # change ownership
  sudo chown ${1}:${1} $ssh_dir

  # now instruct user on how to copy keys
  echo "Execute on your local machine (assumes rpi is on local network):"
  echo "  $ scp ~/.ssh/id_rsa.pub ${1}@$(hostname).local:/home/${1}/.ssh/authorized_keys"
  echo ""


  # now confirm keys are copied, print next steps, and logout
  echo "After keys are copied, logout of pi user and execute the following: "
  echo "  $ ssh ${1}@$(hostname).local"
  echo ""
  echo "Followed by:"
  echo "  $ sudo deluser pi && sudo rm -rf /home/pi"
  exit
}

main(){
  # get new user
  echo -n "Enter name of new raspberrypi user: "
  local newuser
  read newuser

  # check user
  if [[ $newuser ]]; then
      # setup new user
      setup_user "$newuser"

      # setup new ssh key
      setup_sshkey "$newuser"

  else
      echo "User not supplied (Your user was \"${newuser}\". Exiting ..."
      exit
  fi
}

main
