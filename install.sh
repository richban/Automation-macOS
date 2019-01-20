#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Adam Eivy
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./shell/echos.sh
source ./shell/requirers.sh

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."

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
# install XCode
#################################

running "Installing XCode"
xcode-select --install

running "Installing additional SDK headers"
sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /

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

running "install SpaceVim"
curl -sLf https://spacevim.org/install.sh | bash
if [[ $? != 0 ]]; then
	error "unable to install SpaceVim"
	exit 2
fi
  ok "SpaceVim installed"

#################################
# install homebrew (CLI Packages)
#################################

running "checking homebrew install"
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "installing homebrew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    if [[ $? != 0 ]]; then
      error "unable to install homebrew, script $0 abort!"
      exit 2
  fi
else
  ok
  # Make sure we’re using the latest Homebrew
  running "updating homebrew"
  brew update
  ok
  bot "before installing brew packages, we can upgrade any outdated packages."
  read -r -p "run brew upgrade? [y|N] " response
  if [[ $response =~ ^(y|yes|Y) ]];then
      # Upgrade any already-installed formulae
      action "upgrade brew packages..."
      brew upgrade
      ok "brews updated..."
  else
      ok "skipped brew pacskage upgrades.";
  fi
fi

#################################
# install brew cask (UI Packages)
#################################

running "checking brew-cask install"
output=$(brew tap | grep cask)
if [[ $? != 0 ]]; then
  action "installing brew-cask"
  require_brew caskroom/cask/brew-cask
fi
brew tap caskroom/versions > /dev/null 2>&1
ok

# skip those GUI clients, git command-line all the way
require_brew git

# update zsh to latest
require_brew zsh

# update ruby to latest
# use versions of packages installed with homebrew
RUBY_CONFIGURE_OPTS="--with-openssl-dir=`brew --prefix openssl` --with-readline-dir=`brew --prefix readline` --with-libyaml-dir=`brew --prefix libyaml`"
require_brew ruby

# set zsh as the user login shell
CURRENTSHELL=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
if [[ "$CURRENTSHELL" != "/usr/local/bin/zsh" ]]; then
  bot "setting newer homebrew zsh (/usr/local/bin/zsh) as your shell (password required)"
  # sudo bash -c 'echo "/usr/local/bin/zsh" >> /etc/shells'
  # chsh -s /usr/local/bin/zsh
  sudo dscl . -change /Users/$USER UserShell $SHELL /usr/local/bin/zsh > /dev/null 2>&1
  ok
fi

#################################
# install oh-my-zsh
#################################
running "install oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
if [[ $? != 0 ]]; then
	error "unable to install oh-my-zsh"
	exit 2
fi
  ok "oh-my-zsh installed"

#################################
# install asdf
#################################
running "install asdf"
if [ ! -d "$DIRECTORY" ]; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.6.3
fi

if [[ $? != 0 ]]; then
error "unable to clone asdf"
exit 2
fi

ok "asdf installed"


# set oh-my-zsh theme
# if [[ ! -d "./oh-my-zsh/custom/themes/powerlevel9k" ]]; then
#   git clone https://github.com/bhilburn/powerlevel9k.git oh-my-zsh/custom/themes/powerlevel9k
# fi

if [[ -d "/Library/Ruby/Gems/2.0.0" ]]; then
  running "Fixing Ruby Gems Directory Permissions"
  sudo chown -R $(whoami) /Library/Ruby/Gems/2.0.0
  ok
fi

# node version manager
require_brew nvm

# nvm
require_nvm stable

# always pin versions (no surprises, consistent dev/build machines)
npm config set save-exact true

#####################################
# Now we can switch to node.js mode
# for better maintainability and
# easier configuration via
# JSON files and inquirer prompts
#####################################

bot "installing npm tools needed to run this project..."
npm install
ok

bot "installing packages from config.js..."
node index.js
ok

running "cleanup homebrew"
brew cleanup > /dev/null 2>&1
ok

#################################
# Python
#################################

running "Installing Python and packages"

action "install asdf-python plugin"
$HOME/.asdf/bin/asdf plugin-add python https://github.com/danhper/asdf-python.git
if [[ $? != 0 ]]; then
  error "unable to add plugin asdf-python"
  exit 2
fi

action "install specific python version"
$HOME/.asdf/bin/asdf install python 3.7.2
if [[ $? != 0 ]]; then
  error "unable to install python 3.7.2"
  exit 2
fi

action "use python 3.7.2 as default global python"
$HOME/.asdf/bin/asdf global python 3.7.2
if [[ $? != 0 ]]; then
  error "unable to set python 3.7 as global"
  exit 2
fi

action "install jupyter notebook"
pip install jupyter
if [[ $? != 0 ]]; then
  error "unable to install Jupyter Notebook"
  exit 2
fi

ok

#################################
# macOS bootstrap
#################################
source ./macOS-bootstrap.sh
