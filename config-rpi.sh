#!/bin/bash

# Reference: https://gordonlesti.com/change-default-users-on-raspberry-pi/

prompt(){
  # prompt user
  echo -n "$1"
}

fresh_restart(){
  sudo shutdown -r 1
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

setup_rpi_update(){
  # update
  sudo apt-get update
}

setup_docker(){
  # pull down file and execute
  curl -fsSL https://get.docker.com | sh

  # test docker
  sudo docker run tigerj/rpi-whalesay 'Docker successfully installed!!!'
}

setup_hostname(){
  # get new hostname
  prompt "Input new hostname for raspberry pi: "
  local new_hostname
  new_hostname=$(get_response '*' true)

  # update hostname file
  sudo sh -c "echo ${new_hostname} > /etc/hostname" && \

  # update hosts file
  sudo sed -i.bak "s/$(hostname)/${new_hostname}/g" /etc/hosts && \

  # give response
  printf "\n\n"
  echo "Host will now be addressable at: ${new_hostname}.local"
  printf "\n\n"

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
  sudo cat <<EOF | sudo tee -a /etc/network/interfaces
# added through config-rpi.sh script
# ref: https://github.com/RagingTiger/config-rpi
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

  # reminder to logout and delete pi user
  echo "Remember to remove pi user as follows:"
  echo "# login with new USER"
  echo "$ ssh USER@raspberrypi.local"
  echo "raspberrypi:~ $ sudo deluser pi && sudo rm -rf /home/pi"
}

setup_sshkey(){

  # prompt/get response
  prompt "Input username of account to setup sshkey for: "
  local username
  username=$(get_response '*' true)

  # path to .ssh dir
  local ssh_dir="/home/${username}/.ssh"

  # setup .ssh dir in $HOME
  sudo mkdir $ssh_dir

  # change ownership
  sudo chown ${username}:${username} $ssh_dir

  # now instruct user on how to copy keys
  echo "Execute on your local machine (assumes rpi is on local network):"
  echo "  $ scp ~/.ssh/id_rsa.pub ${username}@$(hostname).local:/home/${username}/.ssh/authorized_keys"
  echo ""


  # now confirm keys are copied, print next steps, and logout
  echo "After keys are copied, logout of pi user and execute the following: "
  echo "  $ ssh ${username}@$(hostname).local"
  echo ""
  exit
}

main(){
  # update
  prompt "Would you like to update? (recommended) [Y/n]: "
  get_response setup_rpi_update 'Y' false

  # get new user
  prompt "Would you like to setup a new RPi user? [Y/n]: "
  get_response setup_user 'Y' false

  # get new hostname`
  prompt "Would you like to setup a new hostname? [Y/n]: "
  get_response setup_hostname 'Y' false

  # setup wifi
  prompt "Would you like to setup WiFi? [Y/n]: "
  get_response setup_wifi 'Y' false

  # get docker
  prompt "Would you like to install docker? [Y/n]: "
  get_response setup_docker 'Y' false

  # setup sshkey
  prompt "Would you like to setup an SSH key now? [Y/n]: "
  get_response setup_sshkey 'Y' false

  # restart
  prompt "Restart RPi for changes to take effect (hostname, user)? [Y/n]: "
  get_response fresh_restart 'Y' false
}

# execute
main
