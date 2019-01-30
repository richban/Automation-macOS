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


read -r -p "Do you set up linux? [y|N] " response

if [[ $response =~ (yes|y|Y) ]];then

	#####################################################
	#
	#               Clean & upgrade
	#
	#####################################################

	action "updating ubuntu"
	sudo apt-get -y update > /dev/null 2>&1
	sudo apt-get -y upgrade > /dev/null 2>&1
	ok
	#####################################################
	#
	#           Installing packages
	#
	#####################################################

	action "installing packages"
	sudo apt -y install python python3 python-pip python3-pip python-gtk2 vim git \
	  make build-essential libssl-dev zlib1g-dev libbz2-dev \
	  libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
	  xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev curl python-dbus > /dev/null 2>&1

	[[ $? -ne 0 ]] && exit 1
	ok

	action "installing packages II"
	sudo apt-get -y install qttools5-dev-tools \
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
           libgirepository1.0-dev \
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
			     linuxbrew-wrapper \
			     tmux \
			     zsh > /dev/null 2>&1
	[[ $? -ne 0 ]] && exit 1
	ok
fi


action "make sudo passwordless"
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
	ok
fi

#################################
#  Create Folder Directory
#################################

bot "Creating Developer folder in HOME directory"
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
    bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup"
		ok
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
action "installing brew"
brew > /dev/null 2>&1
ok "brew installed"

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
	action "installing .asdf"
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.3
  echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bashrc
  echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
fi

if [[ $? != 0 ]]; then
exit 2
fi
ok "asdf installed"


#####################################################
#
#                   Setup Python
#
#####################################################


action "installing python plugin"
if [[ ! -d $HOME/.asdf/plugins/python ]]; then
  $HOME/.asdf/bin/asdf plugin-add python https://github.com/danhper/asdf-python.git
fi

if [[ $? != 0 ]]; then
  exit 2
fi

ok "python plugin succesfully added"

action "installing python 3.7.2"
if [[ ! -d $HOME/.asdf/installs/python ]]; then
  $HOME/.asdf/bin/asdf install python 3.7.2
fi

if [[ $? != 0 ]]; then
  exit 2
fi

ok "python 3.7.2 succesfully installed"

$HOME/.asdf/bin/asdf global python 3.7.2
if [[ $? != 0 ]]; then
  exit 2
fi

ok "python configuration installed"

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
    action "Generatinng new ssh-keys"
    . "$CURRENT_DIR/shell/ssh-keys.sh"
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
# dotfiles
#################################

read -r -p "Do you want me to install dotfiles? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    bot "Installing dotfiles"
    git clone --recursive git@github.com:richban/dotfiles.git $HOME/Developer/dotfiles
    cd $HOME/Developer/dotfiles
    action "installing dotdrop manager"
    pip3 install --user -r $HOME/Developer/dotfiles/dotdrop/requirements.txt
    action "installing dotfiles"
    read -r -p "Which profile wish you to install?" profile
    ./dotdrop.sh install --profile=$profile
    ok
fi

#################################
# VREP EDU
#################################
running "installing VREP"
action "downloading VREP-EDU"
if [[ ! -d $HOME/Developer/vrep-edu ]]; then
	cd $HOME/Developer/
	curl http://coppeliarobotics.com/files/V-REP_PRO_EDU_V3_5_0_Linux.tar.gz --output vrep.tar.gz
	tar xzf vrep.tar.gz > /dev/null 2>&1
	mv V-REP_PRO_EDU_V3_5_0_Linux vrep-edu
	rm vrep.tar.gz
	ok
fi

#####################################################
#
#                   Install  Aseba
#
#####################################################

action "installing aseba"
if [[ ! -d $HOME/Developer/aseba ]]; then
    cd ~/Developer
    git clone --recursive https://github.com/aseba-community/aseba.git > /dev/null 2>&1
    cd aseba
    # Building Aseba
    mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF ..
    make
    ok
fi

#####################################################
#
#                   Install  Atom
#
#####################################################

# action "installing atom"
# sudo add-apt-repository -y ppa:webupd8team/atom
# sudo apt -y update; sudo apt -y install atom
# sudo apt -y remove --purge atom
# ok

# User permissions
# sudo usermod -a -G dialout $USER
# sudo newgrp dialout

# set zsh as default terminal
chsh -s $(which zsh)

bot "Woot! All done. Machine will reboot in 5 sec."

sleep 5
sudo shutdown -r 0
