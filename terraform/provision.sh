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
unzip -qawscliv2.zip
sudo ./aws/install

echo 'installing openjdk-14...'
wget -q https://download.java.net/openjdk/jdk14/ri/openjdk-14+36_linux-x64_bin.tar.gz
tar -xzf ./openjdk-14+36_linux-x64_bin.tar.gz
rm ./openjdk-14+36_linux-x64_bin.tar.gz
sudo mkdir -p /usr/local/java
sudo mv ./jdk-14 /usr/local/java
export JAVA_HOME=/usr/local/java/jdk-14
export PATH=$PATH:$JAVA_HOME/bin

# check java version
java -version

echo 'downloading minecraft server jar...'
wget -q https://launcher.mojang.com/v1/objects/35139deedbd5182953cf1caa23835da59ca3d7cd/server.jar -P .
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

echo 'done!'