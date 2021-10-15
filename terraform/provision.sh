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
wget https://download.java.net/openjdk/jdk14/ri/openjdk-14+36_linux-x64_bin.tar.gz
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
sudo mv server.jar /usr/local/bin
echo 'eula=true' > ./eula.txt
sudo mv ./eula.txt /usr/local/bin
