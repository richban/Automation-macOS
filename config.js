module.exports = {
  brew: [
    // http://conqueringthecommandline.com/book/ack_ag
    'ack',
    'ag',
    // alternative to `cat`: https://github.com/sharkdp/bat
    'bat',
    // Install GNU core utilities (those that come with macOS are outdated)
    // Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
    'coreutils',
    'dos2unix',
    // Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed
    'findutils',
    // https://github.com/junegunn/fzf,
    'fzf',
    'readline', // ensure gawk gets good readline
    'gawk',
    'gnupg',
    // Install GNU `sed`, overwriting the built-in `sed`
    // so we can do "sed -i 's/foo/bar/' file" instead of "sed -i '' 's/foo/bar/' file"
    'gnu-sed --with-default-names',
    // upgrade grep so we can get things like inverted match (-v)
    'grep --with-default-names',
    // better, more recent grep
    'homebrew/dupes/grep',
    // https://github.com/jkbrzt/httpie
    'httpie',
    // https://stedolan.github.io/jq/
    'jq',
    // Mac App Store CLI: https://github.com/mas-cli/mas
    'mas',
    // Install some other useful utilities like `sponge`
    'moreutils',
    'nmap',
    'openconnect',
    'reattach-to-user-namespace',
    // better/more recent version of screen
    'homebrew/dupes/screen',
    'tmux',
    // better, more recent vim
    'vim --with-override-system-vi --with-client-server',
    // http://osxdaily.com/2010/08/22/install-watch-command-on-os-x/
    'watch',
    // Install wget with IRI support
    'wget --enable-iri',
    // https://github.com/asdf-vm/asdf
    'asdf',
    // https://github.com/pypa/pipenv
    'readline',
    'xz',
    'mysql@5.7',
    'sqlite',
    'redis',
    'pipenv',
    'graphviz',
    'yarn',
    'broot',
    'koekeishiya/formulae/yabai',
    'koekeishiya/formulae/skhd',
    'fd',
    'exa'
  ],
  cask: [
    'docker', // docker for mac
    'google-chrome',
    'iterm2',
    'slack',
    'visual-studio-code',
    'xquartz',
    'spotify',
    'tldr',
    'shellcheck',
    'hammerspoon'
  ],
  gem: [],
  npm: [
    'eslint',
    'instant-markdown-d',
    'npm-check-updates',
    'prettyjson',
  ],
  mas: []
};
