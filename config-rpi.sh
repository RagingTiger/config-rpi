#!/bin/bash

# Reference: https://gordonlesti.com/change-default-users-on-raspberry-pi/

prompt(){
  # prompt user
  printf "\n\n\n"
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

setup_delpi(){
  # execute only if not pi
  if [[ "$USER" != "pi" ]]; then
    sudo deluser pi && sudo rm -rf /home/pi
  else
    echo "You must create a new user other than 'pi', and login as that user \
          and then rerun this script"
  fi
}

setup_docker(){
  # pull down file and execute
  curl -fsSL https://get.docker.com | sh

  # test docker
  sudo docker run --rm tigerj/whalesay 'Docker successfully installed!!!'
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
  printf "\n"
  echo "Or simply choose to 'Delete pi user' when prompted by config-rpi.sh"
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

setup_sudo_docker_privileges(){
  # reminder to logout and delete pi user
  if [[ "$USER" == "pi" ]]; then
    echo "WARNING: pi user is not secure create a new user, login, and rerun"
    exit
  fi

  # add user to docker group
  echo "You are about to setup sudo privileges for $USER."
  sudo usermod -aG docker $USER
  echo "NOTE: You must logout and login for sudo privileges to take affect"
}

setup_docker_data_path(){
  # get path
  prompt "Input location for new docker data path: "
  local new_data_path
  new_data_path=$(get_response '*' true)

  # set docker daemon.json with new path
  echo "Creating /etc/docker/daemon.json file with new data path"
  sudo cat << EOF | sudo tee /etc/docker/daemon.json
{
  "data-path": "$new_data_path"
}
EOF
}

setup_pi_cam(){
  # Ref: https://raspberrypi.stackexchange.com/questions/14229/how-can-i-
  #      enable-the-camera-without-using-raspi-config#answer-29972
  # add config lines to /boot/config file
  sudo cat << EOF >> /boot/config.txt
start_x=1             # essential
gpu_mem=128           # at least, or maybe more if you wish
disable_camera_led=1  # optional, if you don't want the led to glow
EOF
}

main(){
  # update
  prompt "Would you like to update? (recommended) [Y/n]: "
  get_response setup_rpi_update 'Y' false

  # get new user
  prompt "Would you like to setup a new RPi user? [Y/n]: "
  get_response setup_user 'Y' false

  # delete old user
  prompt "Would you like to delete old RPi user (recommended)? [Y\n]: "
  get_response setup_delpi 'Y' false

  # setup wifi
  prompt "Would you like to setup WiFi? [Y/n]: "
  get_response setup_wifi 'Y' false

  # get docker
  prompt "Would you like to install docker? [Y/n]: "
  get_response setup_docker 'Y' false

  # setup sshkey
  prompt "Would you like to setup an SSH key now? [Y/n]: "
  get_response setup_sshkey 'Y' false

  # get new hostname`
  prompt "Would you like to setup a new hostname? [Y/n]: "
  get_response setup_hostname 'Y' false

  # setup docker sudo privileges
  prompt "Would you like to configure sudo privileges for docker? [Y/n]: "
  get_response setup_sudo_docker_privileges 'Y' false

  # setup docker daemon data path
  prompt "Would you like to change default docker data path? [Y\n]: "
  get_response setup_docker_data_path 'Y' false

  # enable pi camera
  prompt "Would you like to enable Pi Camera? [Y\n]: "
  get_response setup_pi_cam 'Y' false

  # restart
  prompt "Restart RPi for changes to take effect (hostname, user, camera)? [Y/n]: "
  get_response fresh_restart 'Y' false
}

# execute
main
