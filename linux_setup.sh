#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Adam Eivy
# @customized Richard Banyi
# This script performs initiall setup for the
# project and install various dependencies.
# Script is inspired from https://github.com/davla/bash-util

##########################

# include my library helpers for colorized echo and require_brew, etc
source ./shell/echos.sh
source ./shell/requirers.sh

CURRENT_DIR="$PWD"

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."

#####################################################
#
#                   Privileges
#
#####################################################

# Checking for root privileges: if don't
# have them, recalling this script with sudo
if [[ $EUID -ne 0 ]]; then
  echo 'This script needs to be run as root'
  sudo bash "$0" "$@"
  exit 0
fi

#####################################################
#
#               Clean & upgrade
#
#####################################################

# Updating
apt-get update
apt-get upgrade

#####################################################
#
#           Installing packages
#
#####################################################

apt install python python3 python-pip python-gtk2 vim git \
  make build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
  xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev curl python-dbus
[[ $? -ne 0 ]] && exit 1

sudo apt-get install qttools5-dev-tools \
                     qttools5-dev \
                     qtbase5-dev \
                     qt5-qmake \
                     libqt5help5 \
                     libqt5opengl5-dev \
                     libqt5svg5-dev \
                     libqt5x11extras5-dev \
                     libqwt-qt5-dev \
                     libcairo2-dev \
                     libudev-dev \
                     libxml2-dev \
                     libsdl2-dev \
                     libavahi-compat-libdnssd-dev \
                     python-dev \
                     libboost-python-dev \
                     doxygen \
                     cmake \
                     g++ \
                     git \
                     make \
                     autoconf \
                     libreadline-dev \
                     libncurses-dev \
                     libssl-dev \
                     libyaml-dev \
                     libxslt-dev \
                     libffi-dev \
                     libtool \
                     unixodbc-dev \
                     tmux \
                     zsh
[[ $? -ne 0 ]] && exit 1


# User permissions
usermod -a -G dialout $USER
newgrp dialout

# Ask for the administrator password upfront
if ! sudo grep -q "%wheel		ALL=(ALL) NOPASSWD: ALL #atomantic/dotfiles" "/etc/sudoers"; then

  # Ask for the administrator password upfront
  bot "I need you to enter your sudo password so I can install some things:"
  sudo -v

  # Keep-alive: update existing sudo time stamp until the script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  bot "Do you want me to setup this machine to allow you to run sudo without a password?\nPlease read here to see what I am doing:\nhttp://wiki.summercode.com/sudo_without_a_password_in_mac_os_x \n"

  read -r -p "Make sudo passwordless? [y|N] " response

  if [[ $response =~ (yes|y|Y) ]];then
      sudo cp /etc/sudoers /etc/sudoers.back
      echo '%wheel		ALL=(ALL) NOPASSWD: ALL #atomantic/dotfiles' | sudo tee -a /etc/sudoers > /dev/null
      sudo dscl . append /Groups/wheel GroupMembership $(whoami)
      bot "You can now run sudo commands without password!"
  fi
fi

#################################
#  Create Folder Directory
#################################

bot "Create Developer folder in HOME directory"
mkdir -p ~/Developer

#################################
# /etc/hosts
#################################

read -r -p "Overwrite /etc/hosts with the ad-blocking hosts file from someonewhocares.org? (from ./configs/hosts file) [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    action "cp /etc/hosts /etc/hosts.backup"
    sudo cp /etc/hosts /etc/hosts.backup
    ok
    action "cp ./configs/hosts /etc/hosts"
    sudo cp ./configs/hosts /etc/hosts
    ok
    bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup"
fi

#################################
# install SpaceVim
#################################

running "installing SpaceVim"
curl -sLf https://spacevim.org/install.sh | bash
if [[ $? != 0 ]]; then
	error "unable to install SpaceVim"
	exit 2
fi
  ok "SpaceVim installed"

#####################################################
#
#                   Linux Brew
#
#####################################################

sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)" > /dev/null 2>&1

test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >> ~/.bash_profile
echo "eval \$($(brew --prefix)/bin/brew shellenv)" >> ~/.profile


#################################
# install oh-my-zsh
#################################

running "installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" > /dev/null 2>&1
if [[ $? != 0 ]]; then
	error "unable to install oh-my-zsh"
	exit 2
fi
  ok "oh-my-zsh installed"

#################################
# install asdf
#################################

if [[ ! -d $HOME/.asdf ]]; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.3
  echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
  echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.basrc
fi

if [[ $? != 0 ]]; then
exit 2
fi

#####################################################
#
#                   Setup Python
#
#####################################################

if [[ ! -d $HOME/.asdf/plugins/python ]]; then
  $HOME/.asdf/bin/asdf plugin-add python https://github.com/danhper/asdf-python.git
fi

if [[ $? != 0 ]]; then
  exit 2
fi

if [[ ! -d $HOME/.asdf/installs/python ]]; then
  $HOME/.asdf/bin/asdf install python 3.7.2
fi

if [[ $? != 0 ]]; then
  exit 2
fi

$HOME/.asdf/bin/asdf global python 3.7.2
if [[ $? != 0 ]]; then
  exit 2
fi

#################################
# TMUX
#################################
running "cloning tmux manager"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ok

#################################
# ssh-keys 
#################################:w

read -r -p "Do you want me to set up new ssh-keys for this machine? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    bot "Generatinng new ssh-keys"
    . "$CURRENT_DIR/shell/ssh-keys.sh"
    action "adding keys to keychain"
    ssh-add -K
    ok
fi

#################################
# github repositories 
#################################

read -r -p "Do you want me to clone your repositories? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    action "Cloning repos...."
    . "$CURRENT_DIR/shell/clone_repos.sh"
    ok
fi

#################################
# Change Host name
#################################

running "Do you want to change the hostname and computer name? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
	action "changing hostname and computer name"
    read -r -p "Type the new <hostname>" hostname
	sudo scutil --set HostName hostname
	read -r -p "Type the new local <hostname>" localhostname
	sudo scutil --set LocalHostName localhostname
	read -r -p "Type the new computer <name>" computername
	sudo scutil --set ComputerName computername
	action "flushing DNS cache"
	dscacheutil -flushcache
    ok
fi

#################################
# VREP EDU 
#################################
running "installing VREP"
action "downloading VREP-EDU"
cd $HOME/Developer/
curl http://coppeliarobotics.com/files/V-REP_PRO_EDU_V3_5_0_Mac.zip --output vrep-edu.zip

action "unzipping vrep & cleaning up"
unzip vrep-edu.zip > /dev/null 2>&1
mv V-REP_PRO_EDU_V3_5_0_Mac vrep-edu
rm vrep-edu.zip
ok

#####################################################
#
#                   Install  Aseba
#
#####################################################


if [[ ! -d $HOME/Developer ]]; then
    cd ~/ && mkdir ~/Developer && cd developer
    git clone --recursive https://github.com/aseba-community/aseba.git
    cd aseba
    # Building Aseba
    mkdir build && cd build
    cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="<path of qt>;<path of bonjour>" ..
    make
fi

# set zsh as default terminal
chsh -s $(which zsh)

bot "Woot! All done. Kill this terminal and launch iTerm"

