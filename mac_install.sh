#!/usr/bin/env bash

###############################################################################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Adam Eivy
# @customized Richard Banyi
###############################################################################

# include my library helpers for colorized echo and require_brew, etc
source ./shell/echos.sh
source ./shell/requirers.sh

CURRENT_DIR="$PWD"

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."

###############################################################################
bot "Ask for the administrator password upfront"
###############################################################################

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
      sudo dscl . append /Groups/wheel GroupMembership "$(whoami)"
      bot "You can now run sudo commands without password!"
  fi
fi

###############################################################################
bot "Change Host name"
###############################################################################

running "Do you want to change the hostname and computer name? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
	action "changing hostname and computer name"
    read -r -p "Type the new <hostname> :" hostname
	sudo scutil --set HostName hostname
	read -r -p "Type the new local <hostname> :" localhostname
	sudo scutil --set LocalHostName localhostname
	read -r -p "Type the new computer <name> :" computername
	sudo scutil --set ComputerName computername
	action "flushing DNS cache"
	dscacheutil -flushcache
    ok
fi

###############################################################################
bot "install XCode"
###############################################################################

running "Installing XCode"
xcode-select --install

running "Installing additional SDK headers"
sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /

###############################################################################
bot "/etc/hosts -- spyware/ad blocking"
###############################################################################

read -r -p "Overwrite /etc/hosts with the ad-blocking hosts file from someonewhocares.org? (from ./configs/hosts file) [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
  action "cp /etc/hosts /etc/hosts.backup"
  sudo cp /etc/hosts /etc/hosts.backup
  ok
  action "cp ./configs/hosts /etc/hosts"
  sudo cp ./configs/hosts /etc/hosts
  bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup"
  ok
else
  ok "skipped";
fi

###############################################################################
bot "ssh-keys"
###############################################################################

read -r -p "Do you want me to set up new ssh-keys for this machine? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    action "Generatinng new ssh-keys"
    . "$CURRENT_DIR/shell/ssh-keys.sh"
    ok
fi

###############################################################################
bot "Create $HOME/Directory"
###############################################################################

mkdir -p ~/Developer

###############################################################################
bot "Install non-brew various tools (PRE-BREW Installs)"
###############################################################################

if ! xcode-select --print-path &> /dev/null; then

    # Prompt user to install the XCode Command Line Tools
    xcode-select --install &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Wait until the XCode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    print_result $? ' XCode Command Line Tools Installed'

    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10

    sudo xcodebuild -license
    print_result $? 'Agree with the XCode Command Line Tools licence'

fi

###############################################################################
bot "install homebrew (CLI Packages)"
###############################################################################

running "checking homebrew..."
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "installing homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  if [[ $? != 0 ]]; then
    error "unable to install homebrew, script $0 abort!"
    exit 2
  fi
  brew analytics off
else
  ok
  bot "Homebrew"
  read -r -p "run brew update && upgrade? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    action "updating homebrew..."
    brew update
    ok "homebrew updated"
    action "upgrading brew packages..."
    brew upgrade
    ok "brews upgraded"
  else
    ok "skipped brew package upgrades."
  fi
fi

# Just to avoid a potential bug
mkdir -p ~/Library/Caches/Homebrew/Formula
brew doctor

# skip those GUI clients, git command-line all the way
require_brew git
# update zsh to latest
require_brew zsh
# update ruby to latest
# use versions of packages installed with homebrew
RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl) --with-readline-dir=$(brew --prefix readline) --with-libyaml-dir=$(brew --prefix libyaml)"
require_brew ruby
# set zsh as the user login shell
CURRENTSHELL=$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')
if [[ "$CURRENTSHELL" != "/usr/local/bin/zsh" ]]; then
  bot "setting newer homebrew zsh (/usr/local/bin/zsh) as your shell (password required)"
  # sudo bash -c 'echo "/usr/local/bin/zsh" >> /etc/shells'
  # chsh -s /usr/local/bin/zsh
  sudo dscl . -change /Users/"$USER" UserShell "$SHELL" /usr/local/bin/zsh > /dev/null 2>&1
  ok
fi

###############################################################################
bot "Installing packages from node index.js"
###############################################################################

require_brew nvm

# nvm
require_nvm stable

# always pin versions (no surprises, consistent dev/build machines)
npm config set save-exact true

bot "installing npm tools needed to run this project..."
npm install
ok

bot "installing packages from config.js..."
node index.js
ok

running "cleanup homebrew"
brew cleanup --force > /dev/null 2>&1
rm -f -r /Library/Caches/Homebrew/* > /dev/null 2>&1
ok

###############################################################################
bot "oh-my-zsh"
###############################################################################
running "installing oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" > /dev/null 2>&1
if [[ $? != 0 ]]; then
	error "unable to install oh-my-zsh"
	exit 2
fi
  ok "oh-my-zsh installed"

###############################################################################
bot "Installing Fonts"
###############################################################################

read -r -p "Install fonts? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
  bot "installing fonts"
  # need fontconfig to install/build fonts
  require_brew fontconfig
  ./fonts/install.sh
  brew tap homebrew/cask-fonts
  require_cask font-fontawesome
  require_cask font-awesome-terminal-fonts
  require_cask font-hack
  require_cask font-inconsolata-dz-for-powerline
  require_cask font-inconsolata-g-for-powerline
  require_cask font-inconsolata-for-powerline
  require_cask font-roboto-mono
  require_cask font-roboto-mono-for-powerline
  require_cask font-source-code-pro
  ok
fi

###############################################################################
bot "nvm and nodemon"
###############################################################################
running "installing nvm"
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash

action "installing nodemon"
npm install -g nodemon

###############################################################################
bot "SpaceVim"
###############################################################################

running "installing SpaceVim"
curl -sLf https://spacevim.org/install.sh | bash
if [[ $? != 0 ]]; then
  error "unable to install SpaceVim"
  exit 2
fi
ok "SpaceVim installed"

###############################################################################
bot "Powerline10k"
###############################################################################

if [[ ! -d "./oh-my-zsh/custom/themes/powerlevel10k" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM"/themes/powerlevel10k
fi

###############################################################################
bot "tmux"
###############################################################################

if [[ ! -d "$HOME"/.tmux ]]; then
  running "cloning tmux manager"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  ok
fi


###############################################################################
bot "Installing asdf"
###############################################################################

if [[ ! -d "$HOME"/.asdf ]]; then
  action "installing .asdf"
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.7.7
  echo -e "\n. $HOME/.asdf/asdf.sh" >> ~/.bashrc
  echo -e "\n. $HOME/.asdf/completions/asdf.bash" >> ~/.bashrc
fi

if [[ $? != 0 ]]; then
exit 2
fi
ok "asdf installed"

###############################################################################
bot "Installing Python 3.7.5"
###############################################################################

action "installing python plugin"
if [[ ! -d "$HOME"/.asdf/plugins/python ]]; then
  "$HOME"/.asdf/bin/asdf plugin-add python https://github.com/danhper/asdf-python.git
fi

if [[ $? != 0 ]]; then
  exit 2
fi

ok "python plugin succesfully added"

action "installing python 3.7.5"
if [[ ! -d "$HOME"/.asdf/installs/python ]]; then
  "$HOME"/.asdf/bin/asdf install python 3.7.5
fi

if [[ $? != 0 ]]; then
  exit 2
fi

ok "python 3.7.5 succesfully installed"

"$HOME"/.asdf/bin/asdf global python 3.7.5
if [[ $? != 0 ]]; then
  exit 2
fi

ok "python configuration installed"


###############################################################################
bot "VSCODE"
###############################################################################

. "$CURRENT_DIR/shell/vscode.sh"

###############################################################################
bot ".dotfiles"
###############################################################################

read -r -p "Do you want me to install dotfiles? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    bot "Installing dotfiles"
    git clone --recursive git@github.com:richban/dotfiles.git "$HOME"/Developer/dotfiles
    cd "$HOME"/Developer/dotfiles || return
    action "installing dotdrop manager"
    pip3 install --user -r "$HOME"/Developer/dotfiles/dotdrop/requirements.txt
    action "installing dotfiles"
    read -r -p "Which profile wish you to install?" profile
    ./dotdrop.sh install --profile="$profile"
    ok
fi

###############################################################################
bot "configuring general system UI/UX..."
###############################################################################

. "$CURRENT_DIR/osx_general_sys_config.sh"
