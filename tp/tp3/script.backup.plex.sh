#!/bin/bash
# Script de la machine de backup
# hugoj ~ 14/11/2021

sudo dnf -y install nfs-utils

sudo vim /etc/idmapd.conf
Domain = plex.tp3

sudo mkdir /srv/backup
sudo mkdir /srv/backup/server.plex.tp3

sudo vim /etc/exports
/srv/backup 192.168.73.0/24(rw,no_root_squash)

sudo systemctl enable --now nfs-server

sudo firewall-cmd --add-service=nfs

sudo firewall-cmd --runtime-to-permanent

sudo firewall-cmd --reload