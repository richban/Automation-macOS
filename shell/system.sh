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