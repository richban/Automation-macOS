###############################################################################
bot "Installing packages from node index.js"
###############################################################################

read -r -p "Install tools from config.js? [y|N] " response
if [[ $response =~ (y|yes|Y) ]];then
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
fi

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

if [[ ! -d "$HOME"/.nvm ]]; then
    running "installing nvm"
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash 
    action "installing nodemon"
    npm install -g nodemon
fi
###############################################################################
bot "oh-my-zsh"
###############################################################################

if [[ ! -d "$HOME"/.oh-my-zsh ]]; then
    running "installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" > /dev/null 2>&1
    if [[ $? != 0 ]]; then
    error "unable to install oh-my-zsh"
    exit 2
    fi
    ok "oh-my-zsh installed"
fi

###############################################################################
bot "SpaceVim"
###############################################################################

if [[ ! -d "$HOME"/.SpaceVim ]]; then
    running "installing SpaceVim"
    curl -sLf https://spacevim.org/install.sh | bash &>/dev/null &

    if [[ $? != 0 ]]; then
    error "unable to install SpaceVim"
    exit 2
    fi
    ok "SpaceVim installed"
fi

###############################################################################
bot "Powerline10k"
###############################################################################

if [[ ! -d "$HOME"/.oh-my-zsh/themes/powerlevel10k ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME"/.oh-my-zsh/themes/powerlevel10k
fi

###############################################################################
bot "tmux plugin manager"
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
    error "unable to install .asdf"
else
    ok "Succesfully Installed .asdf!"
fi

###############################################################################
bot "Installing Python 3.7.5"
###############################################################################

action "installing python plugin"
if [[ ! -d "$HOME"/.asdf/plugins/python ]]; then
    "$HOME"/.asdf/bin/asdf plugin-add python https://github.com/danhper/asdf-python.git
fi

if [[ $? != 0 ]]; then
    error "unable to .asdf python plugin"
else
    ok "Succesfully installed .asdf!"
fi

action "installing python 3.7.5"
if [[ ! -d "$HOME"/.asdf/installs/python ]]; then
    "$HOME"/.asdf/bin/asdf install python 3.7.5
fi

if [[ $? != 0 ]]; then
    error "unable to install python 3.7.5"
else
    ok "Succesfully installed python 3.7.5!"
fi