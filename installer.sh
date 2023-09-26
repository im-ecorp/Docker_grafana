#!/bin/bash

DBName="iranserver"
USERName="admin"
USERPass="admin"
NS=("nameserver 8.8.8.8"$'\n'"nameserver 4.2.2.4"$'\n'"nameserver 1.1.1.1")
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
sudo wget -q -O /etc/apt/keyrings/grafana.key https://apt.grafana.com/gpg.key
#wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
#To add a repository for stable and beta releases
echo "deb [signed-by=/etc/apt/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
#echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
# Updates the list of available packages
sudo apt-get update
# Installs the latest OSS release:
sudo apt-get install grafana -y
# Installs the latest OSS release:
sudo apt-get install grafana-enterprise -y

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


##########      install telegraf      ############
# influxdata-archive_compat.key GPG fingerprint:
#     9D53 9D90 D332 8DC7 D6C8 D3B9 D8FF 8E1F 7DF8 B07E
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

sudo apt-get update && sudo apt-get install telegraf -y
clear;

mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf-org

sudo tee /etc/telegraf/telegraf.conf<<EOF
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = ""
  omit_hostname = false
[[outputs.influxdb]]
 urls = ["http://localhost:8086"]
 database = "$DBName"
 username = "$USERName"
 password = "$USERPass"

[[outputs.prometheus_client]]
  metric_version = 2
  listen = ":9273"
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]
  mount_points = ["/"]
[[inputs.diskio]]
[[inputs.mem]]
[[inputs.net]]
[[inputs.processes]]
[[inputs.swap]]
[[inputs.system]]
EOF

service telegraf restart


##########      end install telegraf      ############

##########      install influxDB      ############

# influxdata-archive_compat.key GPG Fingerprint: 9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

sudo apt-get update && sudo apt-get install influxdb -y
sudo service influxdb start


influx -execute CREATE USER $USERName WITH PASSWORD '$USERPass' WITH ALL PRIVILEGES 

# Define the regular expression pattern to search for
SEARCH_PATTERN="# auth-enabled = false"

# Define the replacement text
REPLACE_TEXT="auth-enabled = true"

# Use sed to perform the replacement using regular expressions
sed -i "s/$SEARCH_PATTERN/$REPLACE_TEXT/" /etc/influxdb/influxdb.conf

sudo systemctl restart influxdb

influx -username '$USERName' -password '$USERPass' -execute CREATE DATABASE $DBName


##########      end install influxDB      ############

##########      install prometheus      ############

sudo groupadd --system prometheus

sudo useradd -s /sbin/nologin --system -g prometheus prometheus

sudo mkdir /var/lib/prometheus
sudo mkdir /etc/prometheus
sudo apt update
sudo apt -y install wget curl vim

mkdir -p /tmp/prometheus && cd /tmp/prometheus
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep browser_download_url | grep linux-amd64 | cut -d '"' -f 4 | wget -i -
tar xvf prometheus*.tar.gz
cd prometheus*/
sudo mv prometheus promtool /usr/local/bin/

clear;
prometheus --version
sleep 1;
clear;
promtool --version
sleep 1;
clear;

sudo mv prometheus.yml /etc/prometheus/prometheus.yml
sudo mv consoles/ console_libraries/ /etc/prometheus/

cd

text_to_append="  - job_name: 'telegraf'
    static_configs:

    - targets: [\"localhost:9273\"]"

# Append the text to the file
echo -e "$text_to_append" >> /etc/prometheus/prometheus.yml

sudo tee /etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo chown prometheus:prometheus /usr/local/bin/prometheus 
sudo chown prometheus:prometheus /usr/local/bin/promtool 

sudo chown prometheus:prometheus /etc/prometheus 
sudo chown -R prometheus:prometheus /etc/prometheus/consoles 
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries 
sudo chown -R prometheus:prometheus /var/lib/prometheus 



sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus


##########      end install prometheus      ############

















