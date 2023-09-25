#!/bin/bash
NS=("nameserver 8.8.8.8"$'\n'"nameserver 4.2.2.4")
#clear page
clear;
sleep 1;

#append nameserver to the file
echo "$NS" > /etc/resolv.conf

#update repository
sudo apt update;

#update os
sudo apt upgrade -y

clear;

############################         install docker engine        #################################

#uninstall all conflicting packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

#install the latest version
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

clear;
#test for docker is work
sudo docker run hello-world

sleep 1;

clear;

############################       end of installing docker engine       #################################



#############################      install grafana          ################################################
sudo apt-get install -y apt-transport-https software-properties-common wget -y

sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
#To add a repository for stable and beta releases
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
# Updates the list of available packages
sudo apt-get update
# Installs the latest OSS release:
sudo apt-get install grafana -y
# Installs the latest OSS release:
sudo apt-get install grafana -y

#start grafana
sudo systemctl daemon-reload
sudo systemctl start grafana-server
#enable service grafana
sudo systemctl enable grafana-server.service
#restart the grafana service
sudo systemctl restart grafana-server
#init.d service start
sudo service grafana-server start
clear;
#############################    End of install grafana      ################################################

##########      install speedtest      ############
sudo apt-get install curl -y
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
clear;

##########      End install speedtest      ############
