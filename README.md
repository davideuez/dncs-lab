# DNCS-LAB

Design of Networks and Communication Systems, University of Trento. The team is formed by Uez Davide and Luca Calearo

## Contents:

- [Network map](Network-map)
- [Design Requirements](Design-requirements)
- [Our solution for the project](Our-solution-for-the-project)
  - [Subnetting](Subnetting)
  - [Assign IP addresses](Assign-IP-Adresses)
  - [Set a VLAN for the switch](Set-a-VLAN-for-the-switch)
  - [Updated Network map with IP's and VLAN](Updated-Network-map-with-IP's-and-VLAN)
- [Configuring the network](Configuring-the-network)
  - [router-1.sh](router-1.sh)
  - [router-2.sh](router-2.sh)
  - [switch.sh](switch.sh)
  - [host-a.sh](host-a.sh)
  - [host-b.sh](host-b.sh)
  - [host-c.sh](host-c.sh)
- [How to test](How-to-test)
- [Final comments](Final-comments)


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
- *"Hosts-A"*: this subnet contains **"host-a"**, other **509 hosts** and the **router-1 port** (eth1.5)
- *"Hosts-B"*: this subnet contains **"host-b"**, other **180 hosts** and the **router-2 port** (eth1.6)
- *"Hub"*: this subnet contains **"host-c"**, other **509 hosts** and the **router-2 port (eth1.6)**
- *"Connection"*: this subnet contains the 2 ports left on both routers (eth2)

## Assign IP Adresses

To assign IP adresses to the VMs we had to follow th requirements, that say:
- *"Hosts-A"* contains "host-a" and must be able to scale up to 511 usable addresses
- *"Hosts-B"* contains "host-b" and must be able to scale up to 182 usable addresses
- *"Hub"* contains "host-c" must be able to scale up to 511 usable addresses



|     Network     |        Address        |      Netmask    |    Hosts needed    | Hosts available |   Host Min  |   Host Max   |
|:---------------:|:---------------------:|:---------------:|:------------------:|:---------------:|:-----------:|:------------:|
| *Hosts-A*       |  10.0.0.0             |       /22       |         511        |      1022       |  10.0.0.1   |  10.0.3.254  |
| *Hosts-B*       |  10.0.4.0             |       /24       |         182        |      254        |  10.0.4.1   |  10.0.4.254  |
| *Hub*           |  10.0.8.0             |       /22       |         511        |      1022       |  10.0.8.1   |  10.0.11.254 |
| *Connection*    |  10.0.12.0            |       /30       |         2          |      2          |  10.0.12.1  |  10.0.12.2   |

In order to calculate the number of IPs available, we use this formula:
```
Number of available IPs = ((2^X)-2)
```

- **X** refers to the number of bits dedicated to the **host part**.
For our "*Hosts-a*" subnet we chose to assign (32-22=10) 10 bits for the hosts part, so that the number of ip available was closer to the one ask in the requirements
- "-2" is because in every network there are 2 unavailable ip, one for network and oen for broadcast