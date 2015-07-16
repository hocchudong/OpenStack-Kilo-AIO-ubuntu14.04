#!/bin/bash -ex
#
source config.cfg

echo "########## Install NOVA in $LOCAL_IP ##########"
sleep 5 
apt-get -y install nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient nova-compute-kvm
apt-get install libguestfs-tools -y

######## Backup configurations for NOVA ##########"
sleep 7

#
controlnova=/etc/nova/nova.conf
test -f $controlnova.orig || cp $controlnova $controlnova.orig
rm $controlnova
touch $controlnova
cat << EOF >> $controlnova
[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone

#fix loi instances fails to allocate the network
vif_plugging_is_fatal = False
vif_plugging_timeout = 0


my_ip = $LOCAL_IP
vnc_enabled = True
vncserver_listen = $LOCAL_IP
vncserver_proxyclient_address = $LOCAL_IP
novncproxy_base_url = http://$MASTER:6080/vnc_auto.html

# Cho phep thay doi kich thuoc may ao
allow_resize_to_same_host=True
scheduler_default_filters=AllHostsFilter

# Cho phep chen password khi khoi tao
libvirt_inject_password = True
enable_instance_password = True
libvirt_inject_key = true
libvirt_inject_partition = -1

network_api_class = nova.network.neutronv2.api.API
security_group_api = neutron
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver

dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
log_dir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
libvirt_use_virtio_for_bridges=True
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
enabled_apis=ec2,osapi_compute,metadata

[oslo_messaging_rabbit]
rabbit_host = $LOCAL_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[database]
connection = mysql://nova:$NOVA_DBPASS@$LOCAL_IP/nova

[keystone_authtoken]
auth_uri = http://$LOCAL_IP:5000
auth_url = http://$LOCAL_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = nova
password = $NOVA_PASS

[glance]
host = $LOCAL_IP

[oslo_concurrency]
lock_path = /var/lock/nova

[neutron]
url = http://$LOCAL_IP:9696
auth_strategy = keystone
admin_auth_url = http://$LOCAL_IP:35357/v2.0
admin_tenant_name = service
admin_username = neutron
admin_password = $NEUTRON_PASS
service_metadata_proxy = True
metadata_proxy_shared_secret = $METADATA_SECRET


EOF

echo "########## Remove Nova default db ##########"
sleep 7
rm /var/lib/nova/nova.sqlite

echo "########## Syncing Nova DB ##########"
sleep 7 
nova-manage db sync

# fix bug libvirtError: internal error: no supported architecture for os type 'hvm'
echo 'kvm_intel' >> /etc/modules

echo "########## Restarting NOVA ... ##########"
sleep 7 
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service nova-compute restart
sleep 7 
echo "########## Restarting NOVA ... ##########"
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service nova-compute restart


echo "########## Testing NOVA service ##########"
nova-manage service list
