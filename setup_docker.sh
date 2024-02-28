curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh

# ## post installation
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
