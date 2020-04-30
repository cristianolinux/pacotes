#!/bin/bash


systemctl stop postgresql
systemctl stop freeswitch 
systemctl stop vocallsocket
systemctl stop vocallhtml5
systemctl stop vocallintegration


systemctl disable postgresql
systemctl disable freeswitch 
systemctl disable vocallsocket
systemctl disable vocallhtml5
systemctl disable vocallintegration

# Replicando Base de Dados

rm -rf /var/lib/postgresql/9.5/main/pg_* 
rm -Rf /var/lib/postgresql/9.5/main/global
rm -Rf /var/lib/postgresql/9.5/main/base

ln -s /mnt/replica/DB/pg_* /var/lib/postgresql/9.5/main/.
ln -s /mnt/replica/DB/global  /var/lib/postgresql/9.5/main/.
ln -s /mnt/replica/DB/base  /var/lib/postgresql/9.5/main/.


rm -rf  /var/eox
ln -s /mnt/replica/CONFS/var/eox   /var/eox


rm -rf /usr/local/eox/programas/freeswitch/etc/freeswitch
ln -s /mnt/replica/CONFS/etc/etc/freeswitch  /usr/local/eox/programas/freeswitch/etc/freeswitch


