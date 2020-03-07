###############################################################################
bot ".dotfiles"
###############################################################################

read -r -p "Do you want me to install dotfiles? [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    bot "Cloninng dotfiles"
    git clone --recursive https://github.com/richban/dotfiles.git "$HOME"/.dotfiles
    cd "$HOME"/.dotfiles || return
    action "Installing dotdrop manager"
    pip3 install --user -r "$HOME"/.dotfiles/dotdrop/requirements.txt
    ./dotdrop/bootstrap.sh
    action "Installing dotfiles"
    read -r -p "Which profile wish you to install?" profile
    ./dotdrop.sh install --profile="$profile"
    ok
fi
