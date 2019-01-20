#!/usr/bin/env bash

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Adam Eivy
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echos.sh
source ./lib_sh/requirers.sh

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
# Initialize GitHub
#################################

grep 'user = GITHUBUSER' ./homedir/.gitconfig > /dev/null 2>&1
if [[ $? = 0 ]]; then
    read -r -p "What is your github.com username? " githubuser

  fullname=`osascript -e "long user name of (system info)"`

  if [[ -n "$fullname" ]];then
    lastname=$(echo $fullname | awk '{print $2}');
    firstname=$(echo $fullname | awk '{print $1}');
  fi

  if [[ -z $lastname ]]; then
    lastname=`dscl . -read /Users/$(whoami) | grep LastName | sed "s/LastName: //"`
  fi
  if [[ -z $firstname ]]; then
    firstname=`dscl . -read /Users/$(whoami) | grep FirstName | sed "s/FirstName: //"`
  fi
  email=`dscl . -read /Users/$(whoami)  | grep EMailAddress | sed "s/EMailAddress: //"`

  if [[ ! "$firstname" ]];then
    response='n'
  else
    echo -e "I see that your full name is $COL_YELLOW$firstname $lastname$COL_RESET"
    read -r -p "Is this correct? [Y|n] " response
  fi

  if [[ $response =~ ^(no|n|N) ]];then
    read -r -p "What is your first name? " firstname
    read -r -p "What is your last name? " lastname
  fi
  fullname="$firstname $lastname"

  bot "Great $fullname, "

  if [[ ! $email ]];then
    response='n'
  else
    echo -e "The best I can make out, your email address is $COL_YELLOW$email$COL_RESET"
    read -r -p "Is this correct? [Y|n] " response
  fi

  if [[ $response =~ ^(no|n|N) ]];then
    read -r -p "What is your email? " email
    if [[ ! $email ]];then
      error "you must provide an email to configure .gitconfig"
      exit 1
    fi
  fi


  running "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

  # test if gnu-sed or MacOS sed

  sed -i "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig > /dev/null 2>&1 | true
  if [[ ${PIPESTATUS[0]} != 0 ]]; then
    echo
    running "looks like you are using MacOS sed rather than gnu-sed, accommodating"
    sed -i '' "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig;
    sed -i '' 's/GITHUBEMAIL/'$email'/' ./homedir/.gitconfig;
    sed -i '' 's/GITHUBUSER/'$githubuser'/' ./homedir/.gitconfig;
    ok
  else
    echo
    bot "looks like you are already using gnu-sed. woot!"
    sed -i 's/GITHUBEMAIL/'$email'/' ./homedir/.gitconfig;
    sed -i 's/GITHUBUSER/'$githubuser'/' ./homedir/.gitconfig;
  fi
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

# need fontconfig to install/build fonts
require_brew fontconfig

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
# macOS boot-strap
#################################

source ./macOS-bootstrap.sh
