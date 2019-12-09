export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# installing tcpdump
apt-get install -y tcpdump --assume-yes

# enable IP forwarding
sysctl net.ipv4.ip_forward=1

# add IP address to the interface and set it "up"
ip add add 10.0.12.1/30 dev enp0s9
ip link set enp0s9 up

# create a subinterface for VLAN 5
ip link add link enp0s8 name enp0s8.5 type vlan id 5
ip add add 10.0.0.1/22 dev enp0s8.5

# create a subinterfaces for VLAN 6
ip link add link enp0s8 name enp0s8.6 type vlan id 6
ip add add 10.0.4.1/24 dev enp0s8.6

# set interfaces up
ip link set enp0s8 up
ip link set enp0s8.5 up
ip link set enp0s8.6

# delete the default gateway
ip route del default

# create a static route to reach subnet "Hub" via router-2
ip route add 10.0.8.0/22 via 10.0.12.2 dev enp0s9