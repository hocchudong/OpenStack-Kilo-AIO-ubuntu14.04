#!/bin/bash -ex
source config.cfg

apt-get install lvm2 -y

echo "########## Tao Physical Volume va Volume Group (tren disk sdb ) ##########"
fdisk -l
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb

#
echo "########## Cai dat cac goi cho CINDER ##########"
sleep 3
apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient


echo "########## Cau hinh file cho cinder.conf ##########"

filecinder=/etc/cinder/cinder.conf
test -f $filecinder.orig || cp $filecinder $filecinder.orig
rm $filecinder
cat << EOF > $filecinder
[DEFAULT]
rpc_backend = rabbit
my_ip = $LOCAL_IP

rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = tgtadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes


[database]
connection = mysql://cinder:$CINDER_DBPASS@$LOCAL_IP/cinder

[oslo_messaging_rabbit]
rabbit_host = $LOCAL_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

 
[keystone_authtoken]
auth_uri = http://$LOCAL_IP:5000
auth_url = http://$LOCAL_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = cinder
password = $CINDER_PASS

[oslo_concurrency]
lock_path = /var/lock/cinder
EOF

sed  -r -e 's#(filter = )(\[ "a/\.\*/" \])#\1[ "a\/sda1\/", "a\/sdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf

# Phan quyen cho file cinder
chown cinder:cinder $filecinder

echo "########## Dong bo cho cinder ##########"
sleep 3
cinder-manage db sync

echo "########## Khoi dong lai CINDER ##########"
sleep 3
service cinder-api restart
service cinder-scheduler restart
service cinder-volume restart

echo "########## Hoan thanh viec cai dat CINDER ##########"

