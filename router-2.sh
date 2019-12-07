export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# enable IP forwarding
sysctl net.ipv4.ip_forward=1 

# add IP addresses to the interfaces and set it "up"
ip add add 10.0.8.1/22 dev enp0s8
ip add add 10.0.12.2/30 dev enp0s9
ip link set enp0s8 up
ip link set enp0s9 up


# delete the dafault gateway
ip route del default

# Both lines are used to create static routes to reach subnet "Hosts-A" and "Hosts-B" via router-1
ip route add 10.0.0.0/22 via 10.0.12.1 dev enp0s9
ip route add 10.0.4.0/24 via 10.0.12.1 dev enp0s9