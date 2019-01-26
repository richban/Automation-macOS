#!/usr/bin/env bash

bot "Installing Visual Studio code extensions and config."

code -v > /dev/null
if [[ $? -eq 0 ]];then
    read -r -p "Do you want to install VSC extensions? [y|N] " configresponse
    if [[ $configresponse =~ ^(y|yes|Y) ]];then
        ok "Installing extensions please wait..."
        code --install-extension formulahendry.auto-close-tag
        code --install-extension steoates.autoimport 
        code --install-extension coenraads.bracket-pair-colorizer
        code --install-extension dbaeumer.vscode-eslint
        code --install-extension eamodio.gitlens
        code --install-extension oderwat.indent-rainbow 
        code --install-extension sirtori.indenticator
        code --install-extension karyfoundation.theme-karyfoundation-themes
        code --install-extension equinusocio.vsc-material-theme
        code --install-extension christian-kohler.path-intellisense 
        code --install-extension esbenp.prettier-vscode
        code --install-extension ms-python.python
        code --install-extension tht13.python
        code --install-extension humao.rest-client 
        code --install-extension formulahendry.terminal
        code --install-extension wayou.vscode-todo-highlight
        code --install-extension eg2.tslint
        ok "Extensions for VSC have been installed. Please restart your VSC."
    else
        ok "Skipping extension install.";
    fi

    read -r -p "Do you want to overwrite user config? [y|N] " configresponse
    if [[ $configresponse =~ ^(y|yes|Y) ]];then
        cp $HOME/.vscode/settings.json $HOME/Library/Application\ Support/Code/User/settings.json
        ok "New user config has been written. Please restart your VSC."
    else
        ok "Skipping user config overwriting.";
    fi
else
    error "It looks like the command 'code' isn't accessible."
    error "Please make sure you have Visual Studio Code installed"
    error "And that you executed this procedure: https://code.visualstudio.com/docs/setup/mac"
fi
