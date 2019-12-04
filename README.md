# DNCS-LAB

Design of Networks and Communication Systems, University of Trento. The team is formed by Uez Davide and Luca Calearo

## Contents:

- [Network map](#Network-map)
- [Design Requirements](#Design-requirements)
- [Our solution for the project](#Our-solution-for-the-project)
  - [Subnetting](#Subnetting)
  - [Assign IP addresses](#Assign-IP-Adresses)
  - [Set a VLAN](#Set-a-VLAN)
  - [Updated Network map with IP's and VLAN](#Updated-Network-map-with-IP's-and-VLAN)
- [Configuring the network](#Configuring-the-network)
  - [router-1.sh](#ROUTER-1)
  - [router-2.sh](#ROUTER-2)
  - [switch.sh](#SWITCH)
  - [host-a.sh](#HOST-A)
  - [host-b.sh](#HOST-B)
  - [host-c.sh](#HOST-C)
- [How to test](#How-to-test)
- [Final comments](#Final-comments)


 # Network map

```
        +-----------------------------------------------------+
        |                                                     |
        |                                                     |eth0
        +--+--+                +------------+             +------------+
        |     |                |            |             |            |
        |     |            eth0|            |eth2     eth2|            |
        |     +----------------+  router-1  +-------------+  router-2  |
        |     |                |            |             |            |
        |     |                |            |             |            |
        |  M  |                +------------+             +------------+
        |  A  |                      |eth1                       |eth1
        |  N  |                      |                           |
        |  A  |                      |                           |
        |  G  |                      |                     +-----+----+
        |  E  |                      |eth1                 |          |
        |  M  |            +-------------------+           |          |
        |  E  |        eth0|                   |           |  host-c  |
        |  N  +------------+      SWITCH       |           |          |
        |  T  |            |                   |           |          |
        |     |            +-------------------+           +----------+
        |  V  |               |eth2         |eth3                |eth0
        |  A  |               |             |                    |
        |  G  |               |             |                    |
        |  R  |               |eth1         |eth1                |
        |  A  |        +----------+     +----------+             |
        |  N  |        |          |     |          |             |
        |  T  |    eth0|          |     |          |             |
        |     +--------+  host-a  |     |  host-b  |             |
        |     |        |          |     |          |             |
        |     |        |          |     |          |             |
        ++-+--+        +----------+     +----------+             |
        | |                              |eth0                   |
        | |                              |                       |
        | +------------------------------+                       |
        |                                                        |
        |                                                        |
        +--------------------------------------------------------+

```

# Design Requirements
- Hosts 1-a and 1-b are in two subnets (*Hosts-A* and *Hosts-B*) that must be able to scale up to respectively 511 and 182 usable addresses
- Host 2-c is in a subnet (*Hub*) that needs to accommodate up to 511 usable addresses
- Host 2-c must run a docker image (dustnic82/nginx-test) which implements a web-server that must be reachable from Host-1-a and Host-1-b
- No dynamic routing can be used
- Routes must be as generic as possible
- The lab setup must be portable and executed just by launching the `vagrant up` command

# Our solution for the project

## Subnetting

We decide to divide our network in 4 sub-networks, with 2 of these that are VLAN based (to "split" the switch into two virtual switches). 

The 4 networks are:
- *"Hosts-A"*: this subnet contains **"host-a"**, other **509 hosts** and the **router-1 port** (enp0s8.5)
- *"Hosts-B"*: this subnet contains **"host-b"**, other **180 hosts** and the **router-2 port** (enp0s8.6)
- *"Hub"*: this subnet contains **"host-c"**, other **509 hosts** and the **router-2 port (enp0s8)**
- *"Connection"*: this subnet contains the 2 ports left on both routers (enp0s9 on both)

## Assign IP Adresses

We used IPs starting from 10.0.0.0 because there is no specification for a certain pool of addresses in requirements.

To assign IP adresses to the VMs we had to follow the requirements, that say:
- *"Hosts-A"* contains "host-a" and must be able to scale up to 511 usable addresses
- *"Hosts-B"* contains "host-b" and must be able to scale up to 182 usable addresses
- *"Hub"* contains "host-c" must be able to scale up to 511 usable addresses

|     Subnet     |        Address        |      Netmask    |    Hosts needed    | Hosts available |   Host Min  |   Host Max   |
|:---------------:|:---------------------:|:---------------:|:------------------:|:---------------:|:-----------:|:------------:|
| *Hosts-A*       |  10.0.0.0             |       /22       |         511        |      1022       |  10.0.0.1   |  10.0.3.254  |
| *Hosts-B*       |  10.0.4.0             |       /24       |         182        |      254        |  10.0.4.1   |  10.0.4.254  |
| *Hub*           |  10.0.8.0             |       /22       |         511        |      1022       |  10.0.8.1   |  10.0.11.254 |
| *Connection*    |  10.0.12.0            |       /30       |         2          |      2          |  10.0.12.1  |  10.0.12.2   |

In order to calculate the number of IPs available, we use this formula:
```
Number of available IPs for network = ((2^X)-2)
```

- **X** refers to the number of bits dedicated to the **host part**.
For our "*Hosts-a*" subnet we chose to assign (32-22=10) 10 bits for the hosts part, so that the number of ip available was closer to the one ask in the requirements
- "-2" is because in every network there are 2 unavailable ip, one for network and oen for broadcast

## Set a VLAN

| Subnet | Interface | Vlan tag |     IP     |
|:------:|:---------:|:--------:|:----------:|
|    *Hosts-A*   | enp0s8.5  |    5    | 10.0.0.1 |
|    *Hosts-B*   | enp0s8.6  |    6    | 10.0.4.1 |

We decided to use vlans for the networks "*Hosts-A*" and "*Hosts-B*", so we can split the switch in two virtual switches. 

- SWITCH: split in two VLAN: "VLAN 5" and "VLAN 6"
- ROUTER-1: created a link between router-1 and VLANs in trunk mode

## Updated Network map with IP's and VLAN

```


        +----------------------------------------------------------+
        |                           10.0.12.1/30     10.0.12.2/30  |
        |                                 enp0s9       enp0s9      |enp0s3
        +--+--+                +------------+  ^          ^   +------------+
        |     |                |            |  |          |   |            |
        |     |          enp0s3|            |  |          |   |            |
        |     +----------------+  router-1  +-----------------+  router-2  |
        |     |                |            |                 |            |
        |     |                |            |                 |            |
        |  M  |                +------------+                 +------------+
        |  A  |         10.0.0.1/22  |  enp0s8.5                 |enp0s8 10.0.8.1/22
        |  N  |         10.0.4.1/24  |  enp0s8.6                 |
        |  A  |                      |                           |enp0s8 10.0.8.2/22
        |  G  |                      |                     +-----+----+
        |  E  |                      |  enp0s8             |          |
        |  M  |            +-------------------+           |          |
        |  E  |      enp0s3|                   |           |  host-c  |
        |  N  +------------+      SWITCH       |           |          |
        |  T  |            |  5             6  |           |          |
        |     |            +-------------------+           +----------+
        |  V  |        enp0s9 |             | enp0s10            |enp0s3
        |  A  |               |             |                    |
        |  G  |               |10.0.0.2/22  |10.0.4.2/24         |
        |  R  |               |enp0s8       |enp0s8              |
        |  A  |        +----------+     +----------+             |
        |  N  |        |          |     |          |             |
        |  T  |  enp0s3|          |     |          |             |
        |     +--------+  host-a  |     |  host-b  |             |
        |     |        |          |     |          |             |
        |     |        |          |     |          |             |
        ++-+--+        +----------+     +----------+             |
        | |                              |enp0s3                 |
        | |                              |                       |
        | +------------------------------+                       |
        |                                                        |
        |                                                        |
        +--------------------------------------------------------+



```

# Configuring the network

## ROUTER-1

```
export DEBIAN_FRONTEND=noninteractive
sudo su

# 1
sysctl net.ipv4.ip_forward=1

# 2
ip add add 10.0.12.1/30 dev enp0s9
ip link set enp0s9 up

# 3
ip link add link enp0s8 name enp0s8.5 type vlan id 5
ip add add 10.0.0.1/22 dev enp0s8.5

# 4
ip link add link enp0s8 name enp0s8.6 type vlan id 6
ip add add 10.0.4.1/24 dev enp0s8.6

# 5
ip link set enp0s8 up
ip link set enp0s8.5 up
ip link set enp0s8.6

# 6
ip route del default

# 7
ip route add 10.0.8.0/22 via 10.0.12.2 dev enp0s9
```

What does this code mean?

1. Enable IP forwarding
2. Add IP address to the interface linked to router-2 and set it "up"
3. Create a subinterface for VLAN 5
4. Create a subinterfaces for VLAN 6
5. Set interfaces towards the switch up
6. Delete the default gateway
7. Create a static route to reach subnet "Hub" (where there is Host-c) via router-2

## ROUTER-2

```
export DEBIAN_FRONTEND=noninteractive
sudo su

# 1
sysctl net.ipv4.ip_forward=1 

# 2
ip add add 10.0.8.1/22 dev enp0s8
ip add add 10.0.12.2/30 dev enp0s9
ip link set enp0s8 up
ip link set enp0s9 up


# 3
ip route del default

# 4
ip route add 10.0.0.0/22 via 10.0.12.1 dev enp0s9
ip route add 10.0.4.0/24 via 10.0.12.1 dev enp0s9
```

What does this code mean?

1. Enable IP forwarding
2. Add IP address to the interfaces and set them "up"
3. Delete the dafault gateway
4. Both lines are used to create static routes to reach subnet "Hosts-A" and "Hosts-B" via router-1

## SWITCH

```
export DEBIAN_FRONTEND=noninteractive

sudo su
apt-get update

# 1
apt-get install -y tcpdump
apt-get install -y openvswitch-common openvswitch-switch apt-transport-https ca-certificates curl software-properties-common

# 2
ovs-vsctl add-br br0

# 3
ovs-vsctl add-port br0 enp0s8
ip link set enp0s8 up

# 4
ovs-vsctl add-port br0 enp0s9 tag=5
ip link set enp0s9 up

# 5
ovs-vsctl add-port br0 enp0s10 tag=6
ip link set enp0s10 up
```

What does this code mean?

1. Installing tcpdump, openvswitch and curl
2. Creates a new bridge "br0"
3. Creates a trunk port and set interface up
4. Add a port on the bridge with tag=5 (VLAN 5) and set the interface up
5. Add a port on the bridge with tag=6 (VLAN 6) and set the interface up

## HOST-A

```
export DEBIAN_FRONTEND=noninteractive
sudo su

# 1
ip add add 10.0.0.2/22 dev enp0s8
ip link set enp0s8 up

# 2
ip route del default

# 3
ip route add default via 10.0.0.1
```

What does this code mean?

1. Add IP address to the interface and set it "up"
2. Delete the default gateway
3. Sets the default gateway on router-1

## HOST-B

```
export DEBIAN_FRONTEND=noninteractive
sudo su

# 1
ip add add 10.0.4.2/24 dev enp0s8
ip link set enp0s8 up

# 2
ip route del default

# 3
ip route add default via 10.0.4.1
```

What does this code mean?

1. Add IP address to the interface and set it "up"
2. Delete the default gateway
3. Sets the default gateway on router-1

## HOST-C

```
export DEBIAN_FRONTEND=noninteractive

sudo su
apt-get update

# 1
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

# 2
docker system prune -a
docker run --name DNCSWebserver -p 80:80 -d dustnic82/nginx-test

# 3
ip add add 10.0.8.2/24 dev enp0s8
ip link set enp0s8 up


# 4
ip route add 10.0.0.0/22 via 10.0.8.1
ip route add 10.0.4.0/24 via 10.0.8.1
```

What does this code mean?

1. Install docker and curl
2. First clean and then run docker image "dustnic82/nginx-test"
3. Add IP address to the interface and set it "up"
4. Both lines are used to create static routes to reach subnet "Hosts-A" and "Hosts-B" via router-2