#!/usr/bin/env bash

rm -rf nvim-linux64 nvim-treesitter

git clone --depth=1 'https://github.com/nvim-treesitter/nvim-treesitter'
# git --git-dir ./nvim-treesitter/.git rev-parse --short HEAD > ./tag

wget 'https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz'
tar xzf nvim-linux64.tar.gz
rm nvim-linux64.tar.gz

./nvim-linux64/bin/nvim --headless -u ./init.lua -c 'q'

rm -rf nvim-linux64 nvim-treesitter
