#!/bin/bash

# VARIAVEIS
IP=$1
IPCLUSTER=$2
IPHA1=10.10.10.1
IPHA2=10.10.10.2
VARINT=`ip link show  |grep DOWN | awk -F ":" '{print $2}'`

if test -n "${IP}" && test "${IPCLUSTER}"; then
ssh-keygen
ssh-copy-id suporte@${IP}

# CONFIGURANDO IP [HA] NO SERVIDOR PRIMARIO - {
# Backup
cp -p /etc/network/interfaces /etc/network/interfaces-bkp
echo "
auto ${VARINT}
iface ${VARINT} inet static
address ${IPHA1}
netmask 255.255.255.0

" >> /etc/network/interfaces

ifup ${VARINT}
ifconfig ${VARINT} up

###
echo "

${IPHA1} node1 
${IPHA2} node2

" >> /etc/hosts


# Instalando pacotes
apt-get install rsync pacemaker libxml2-utils -y 

corosync-keygen -l -k /etc/corosync/authkey
echo ""
mv /etc/corosync/corosync.conf /etc/corosync/corosync.conf-bkp

echo "
totem {
  version: 2
  cluster_name: lbcluster
  transport: udpu
  interface {
    ringnumber: 0
    bindnetaddr: node1
    broadcast: yes
    mcastport: 5404
  }
}

quorum {
  provider: corosync_votequorum
  two_node: 1
}

nodelist {
  node {
    ring0_addr: node1
    name: primary
    nodeid: 1
  }
  node {
    ring0_addr: node2
    name: secondary
    nodeid: 2
  }
}

logging {
  to_logfile: yes
  logfile: /var/log/corosync/corosync.log
  to_syslog: yes
  timestamp: on
}

service {
  name: pacemaker
  ver: 1
}


"  > /etc/corosync/corosync.conf

systemctl restart corosync

crm node delete ${HOSTNAME}

update-rc.d pacemaker defaults 20 01

systemctl start pacemaker


crm configure property stonith-enabled=false
crm configure property no-quorum-policy=ignore


cp -p ${HOME}/eox-agent  /usr/lib/ocf/resource.d/heartbeat/
cp -p  ${HOME}/eox.sh /usr/local/bin/eox.sh
chmod +x /usr/local/bin/eox.sh

cp -Rp /etc/corosync/ ${HOME}/



rsync -ravz --progress  ${HOME} suporte@${IP}:. 


ssh -t suporte@${IP} 'sudo ./root/HAremoto.sh'


crm configure primitive FloatIP ocf:heartbeat:IPaddr2 params ip="$IPCLUSTER" cidr_netmask="24" op monitor interval="10s"


crm configure primitive Eox-Agent ocf:heartbeat:eox-agent

#crm status


crm configure colocation Cluster inf:  Eox-Agent FloatIP


crm configure order FloatIP-Antes-EOX inf: FloatIP Eox-Agent

cp  /usr/local/eox/programas/freeswitch/conf/sip_profiles/internal.xml  /usr/local/eox/programas/freeswitch/conf/sip_profiles/internal.xml-bkp
sed -i 's/$${local_ip_v4}/'"${IPCLUSTER}"'/g' /usr/local/eox/programas/freeswitch/conf/sip_profiles/internal.xml



else
echo "Preencha com IP do Servidor remoto e IP Flutuante do Cluster";

fi

