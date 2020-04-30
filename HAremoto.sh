#!/bin/bash

# Adiciona INTERFACE NO SERVIDOR REMOTO


IPHA1=10.10.10.1
IPHA2=10.10.10.2
VARINT=`ip link show  |grep DOWN | awk -F ":" '{print $2}'`

# instala pacotes
apt-get install rsync pacemaker libxml2-utils -y 


# Backup
cp -p /etc/network/interfaces /etc/network/interfaces-bkp
echo "
auto ${VARINT}
iface ${VARINT} inet static
address ${IPHA2}
netmask 255.255.255.0

" >> /etc/network/interfaces

ifup ${VARINT}

###
echo "

${IPHA1} node1 
${IPHA2} node2

" >> /etc/hosts


mv /etc/corosync/corosync.conf /etc/corosync/corosync.conf-bkp

cp -p ${HOME}/root/corosync/*  /etc/corosync/

systemctl restart corosync

crm node delete ${HOSTNAME}

update-rc.d pacemaker defaults 20 01

systemctl start pacemaker


cp -p ${HOME}/root/eox-agent  /usr/lib/ocf/resource.d/heartbeat/
cp -p ${HOME}/root/eox.sh /usr/local/bin/eox.sh
chmod +x /usr/local/bin/eox.sh



