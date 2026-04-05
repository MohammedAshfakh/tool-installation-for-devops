#!/bin/bash

sudo apt update -y
echo "------------------------------Installing Open JDK  -------------------------------------------"
sudo apt install openjdk-17-jdk -y
sudo apt install fontconfig openjdk-21-jre -y
java -version

echo "----------------------Installing depending libraries for Jenkins ---------------------------------"
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "-------------------------update system and install Jenkins ---------------------------------------"
sudo apt update -y
sudo apt install jenkins -y


echo "----------------------------starting and enabling of jenkins ---------------------------"
sudo systemctl enable jenkins 
sudo systemctl start jenkins
sudo systemctl status jenkins

