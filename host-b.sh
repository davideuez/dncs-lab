export DEBIAN_FRONTEND=noninteractive
sudo su

# adds IP address to the interface and set it "up"
ip add add 10.0.4.2/24 dev enp0s8
ip link set enp0s8 up

# delete the dafault gateway
ip route del default

# sets the default gateway on router-1
ip route add default via 10.0.4.1