###############################################################################
bot ".dotfiles"
###############################################################################

read -r -p "Do you want me to install dotfiles? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    bot "Installing dotfiles"
    git clone --recursive https://github.com/richban/setupbot-osx-linux.git "$HOME"/.dotfiles
    cd "$HOME"/Developer/dotfiles || return
    action "installing dotdrop manager"
    pip3 install --user -r "$HOME"/.dotfiles/dotdrop/requirements.txt
    action "installing dotfiles"
    read -r -p "Which profile wish you to install?" profile
    ./dotdrop.sh install --profile="$profile"
    ok
fi
