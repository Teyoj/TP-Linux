#!/bin/bash
# Script d'installation plex.server
# hugoj ~ 14/11/2021

# J'installe Plex Media Server en ajoutant le repo officiel de Plex

sudo nano /etc/yum.repos.d/plex.repo

[PlexRepo]
name=PlexRepo
baseurl=https://downloads.plex.tv/repo/rpm/$basearch/
enabled=1
gpgkey=https://downloads.plex.tv/plex-keys/PlexSign.key
gpgcheck=1

sudo dnf -y install plexmediaserver

sudo systemctl start plexmediaserver
sudo systemctl enable plexmediaserver

sudo firewall-cmd --add-service=plex --zone=public --permanent
sudo firewall-cmd --reload

# Monitoring

sudo su -

bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh)

exit

sudo systemctl start netdata
sudo systemctl enable netdata

sudo firewall-cmd --add-port=19999/tcp --permanent
sudo firewall-cmd --reload

# Backup

sudo dnf -y install nfs-utils

sudo vim /etc/idmapd.conf
Domain = plex.tp3

sudo mkdir /srv/backup

sudo mount -t nfs backup.plex.tp3:/srv/backup/server.plex.tp3 /srv/backup
df -hT

sudo vim /etc/fstab
backup.plex.tp3:/srv/backup/server.plex.tp3 /srv/backup nfs defaults 0 0

