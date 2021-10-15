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

echo 'downloading node_exporter...'
wget -q https://github.com/prometheus/node_exporter/releases/download/v1.2.2/node_exporter-1.2.2.linux-amd64.tar.gz
tar xvfz node_exporter-1.2.2.linux-amd64.tar.gz
sudo mv ./node_exporter-1.2.2.linux-amd64/node_exporter /usr/local/bin/node_exporter

echo 'downloading minecraft_prometheus_exporter...'
wget -q https://github.com/dirien/minecraft-prometheus-exporter/releases/download/v0.6.0/minecraft-exporter_0.6.0.linux-amd64.tar.gz
tar -xzf minecraft-exporter_0.6.0.linux-amd64.tar.gz
sudo mv ./minecraft-exporter /usr/local/bin