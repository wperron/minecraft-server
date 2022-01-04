#!/bin/bash
mkdir -p /tmp/build
cd /tmp/build

echo 'updating package repo...'
sudo apt-get update -y
echo 'installing dependencies...'
sudo apt-get install -y \
  curl \
  wget \
  zip \
  ca-certificates \
  apt-transport-https \
  gnupg

echo 'installing aws cli v2...'
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install

echo 'installing openjdk-14...'
sudo apt-get install -y openjdk-16-jre-headless

# check java version
java -version

echo 'downloading minecraft server jar...'
wget -q https://launcher.mojang.com/v1/objects/a16d67e5807f57fc4e550299cf20226194497dc2/server.jar -P .
mkdir -p /home/ubuntu/server
sudo mv server.jar /usr/local/bin
echo 'eula=true' > ./eula.txt
mv ./eula.txt /home/ubuntu/server
sudo mv /tmp/minecraft.service /etc/systemd/system/

echo 'downloading minecraft_prometheus_exporter...'
wget -q https://github.com/dirien/minecraft-prometheus-exporter/releases/download/v0.6.0/minecraft-exporter_0.6.0.linux-amd64.tar.gz
tar -xzf minecraft-exporter_0.6.0.linux-amd64.tar.gz
sudo mv ./minecraft-exporter /usr/local/bin
sudo mv /tmp/minecraft_exporter.service /etc/systemd/system

echo 'downloading vector agent...'
curl -1sLf 'https://repositories.timber.io/public/vector/cfg/setup/bash.deb.sh' | sudo -E bash
sudo apt-get install -y vector
sudo mv /tmp/vector.toml /etc/vector/vector.toml

echo 'enabling systemd services...'
sudo systemctl enable minecraft
sudo systemctl enable minecraft_exporter
sudo systemctl enable vector

echo 'done!'