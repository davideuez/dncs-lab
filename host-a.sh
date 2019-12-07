export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# adds IP address to the interface and set it "up"
ip add add 10.0.0.2/22 dev enp0s8
ip link set enp0s8 up

# delete the default gateway
ip route del default

# sets the default gateway on router-1
ip route add default via 10.0.0.1