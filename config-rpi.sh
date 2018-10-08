#!/bin/bash

# Reference: https://gordonlesti.com/change-default-users-on-raspberry-pi/

prompt(){
  # prompt user
  echo -n "$1"

}

get_response(){
  # get user input
  local response
  read response

  # determine action
  case $response in
    $2)
      # execute function

      $1
      ;;

    *)
      # do nothing
      :
      ;;
  esac

  # optional return
  if $3; then
    echo "$response"
  fi
}

setup_docker(){
  # pull down file and execute
  cd /tmp || exit
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get_docker.sh
}

setup_wifi(){
  # prompt for ssid
  prompt "Input SSID for wifi (name of wifi): "
  local ssid
  ssid=$(get_response '*' true)

  # prompt for password
  prompt "Input password for wifi: "
  local psswd
  psswd=$(get_response '*' true)

  # create here doc and append to file
  cat <<EOF >> $1
auto lo

iface lo inet loopback
iface eth0 inet dhcp

allow-hotplug wlan0
auto wlan0


iface wlan0 inet dhcp
        wpa-ssid "$ssid"
        wpa-psk "$psswd"
EOF
}

setup_user(){
  # prompt/get response
  prompt "Input new username: "
  local username
  username=$(get_response '*' true)

  # next add new user
  sudo adduser $username

  # now add to sudo group
  sudo adduser $username sudo
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
  prompt "Would you like to setup new RPi user? [Y/n]: "
  get_response setup_user 'Y' false

  # setup wifi
  prompt "Would you like to setup WiFi? [Y/n]: "
  get_response setup_wifi 'Y' false

  # get docker
  prompt "Would you like to install docker? [Y/n]: "
  get_response setup_docker 'Y' false

  # setup sshkey
  prompt "Would you like to setup an SSH key now? [Y/n]: "
  get_response setup_sshkey 'Y' false
}

main
