#!/bin/bash -i
cd ~
wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzvf  go1.22.1.linux-amd64.tar.gz
echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc