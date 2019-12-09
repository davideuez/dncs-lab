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
- [Vagrantfile](#Vagranfile)
- [Configuring the network](#Configuring-the-network)
  - [router-1.sh](#ROUTER-1)
  - [router-2.sh](#ROUTER-2)
  - [switch.sh](#SWITCH)
  - [host-a.sh](#HOST-A)
  - [host-b.sh](#HOST-B)
  - [host-c.sh](#HOST-C)
- [How to test](#How-to-test)
- [Members and repository information](#Members-and-repository-information)


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

# Vagrantfile

This is an example extract from the Vagrantfile, that show how Vagrant create a new VM, based on our settings.

We modified 2 things:
- at line 5 we change the path of the .sh file for every VM, linking the correct configuration file for every machine
- at line 7 we increase the memory just for Host-c, because it is "hosting" the docker and need a bit more energy

```
1   config.vm.define "host-c" do |hostc|
2       hostc.vm.box = "ubuntu/bionic64"
3       hostc.vm.hostname = "host-c"
4       hostc.vm.network "private_network", virtualbox__intnet: "broadcast_router-south-2", auto_config: false
5       hostc.vm.provision "shell", path: "host-c.sh"
6       hostc.vm.provider "virtualbox" do |vb|
7         vb.memory = 512
```



# Configuring the network

## ROUTER-1

```
export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# 1
apt-get install -y tcpdump --assume-yes

# 2
sysctl net.ipv4.ip_forward=1

# 3
ip add add 10.0.12.1/30 dev enp0s9
ip link set enp0s9 up

# 4
ip link add link enp0s8 name enp0s8.5 type vlan id 5
ip add add 10.0.0.1/22 dev enp0s8.5

# 5
ip link add link enp0s8 name enp0s8.6 type vlan id 6
ip add add 10.0.4.1/24 dev enp0s8.6

# 6
ip link set enp0s8 up
ip link set enp0s8.5 up
ip link set enp0s8.6

# 7
ip route del default

# 8
ip route add 10.0.8.0/22 via 10.0.12.2 dev enp0s9
```

What does this code mean?

1. Installing tcpdump for debug and sniffing purposes
2. Enable IP forwarding
3. Add IP address to the interface linked to router-2 and set it "up"
4. Create a subinterface for VLAN 5
5. Create a subinterfaces for VLAN 6
6. Set interfaces towards the switch up
7. Delete the default gateway
8. Create a static route to reach subnet "Hub" (where there is Host-c) via router-2

## ROUTER-2

```
export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# 1
apt-get install -y tcpdump --assume-yes

# 2
sysctl net.ipv4.ip_forward=1 

# 3
ip add add 10.0.8.1/22 dev enp0s8
ip add add 10.0.12.2/30 dev enp0s9
ip link set enp0s8 up
ip link set enp0s9 up


# 4
ip route del default

# 5
ip route add 10.0.0.0/22 via 10.0.12.1 dev enp0s9
ip route add 10.0.4.0/24 via 10.0.12.1 dev enp0s9
```

What does this code mean?

1. Installing tcpdump for debug and sniffing purposes
2. Enable IP forwarding
3. Add IP address to the interfaces and set them "up"
4. Delete the dafault gateway
5. Both lines are used to create static routes to reach subnet "Hosts-A" and "Hosts-B" via router-1

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
apt-get update

# 1
apt-get install -y tcpdump --assume-yes

# 2
ip add add 10.0.0.2/22 dev enp0s8
ip link set enp0s8 up

# 3
ip route del default

# 4
ip route add default via 10.0.0.1
```

What does this code mean?

1. Installing tcpdump for debug and sniffing purposes
2. Add IP address to the interface and set it "up"
3. Delete the default gateway
4. Sets the default gateway on router-1

## HOST-B

```
export DEBIAN_FRONTEND=noninteractive
sudo su
apt-get update

# 1
apt-get install -y tcpdump --assume-yes

# 2
ip add add 10.0.4.2/24 dev enp0s8
ip link set enp0s8 up

# 3
ip route del default

# 4
ip route add default via 10.0.4.1
```

What does this code mean?

1. Installing tcpdump for debug and sniffing purposes
2. Add IP address to the interface and set it "up"
3. Delete the default gateway
4. Sets the default gateway on router-1

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

# How to test

1. Install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/)
2. Clone this repository in your computer, using "Download ZIP" or using the "git clone" command
3. Open a terminal and navigate to the folder that you installed (using the command "cd") and then use the command ```vagrant up``` to start generating all the Virtual Machines. This process can take several minutes to install all VMs.
4. Once the terminal has ended all the process of installation, you can check if everything is working fine using the command ```vagrant status```. It should return these lines:

```
Current machine states:

router-1                  running (virtualbox)
router-2                  running (virtualbox)
switch                    running (virtualbox)
host-a                    running (virtualbox)
host-b                    running (virtualbox)
host-c                    running (virtualbox)
```

If your terminal display something different just uninstall the setup with ```vagrant destroy``` and try the installation process again.

5. Once your environment is up and running you can log into every single VM just by typing ```vagrant ssh VMname``` , changing "VMname" with the name of the VM which you want to move into. For example if you want to navigate to router-1 you have to type:

```
vagrant ssh router-1
```

and this will display some information about the VM

```
Welcome to Ubuntu 18.04.3 LTS (GNU/Linux 4.15.0-66-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sat Dec  7 17:04:36 UTC 2019

  System load:  0.0               Processes:             86
  Usage of /:   11.5% of 9.63GB   Users logged in:       1
  Memory usage: 49%               IP address for enp0s3: 10.0.2.15
  Swap usage:   0%                IP address for enp0s9: 10.0.12.1


56 packages can be updated.
30 updates are security updates.


Last login: Sat Dec  7 16:46:00 2019 from 10.0.2.2
```

6. For every VM we can use the command ```ifconfig``` to display the list of all Ethernet interfaces on the host, with their own options. This is an example on host-a:

```
enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.2.15  netmask 255.255.255.0  broadcast 10.0.2.255
        inet6 fe80::c7:16ff:fecf:8450  prefixlen 64  scopeid 0x20<link>
        ether 02:c7:16:cf:84:50  txqueuelen 1000  (Ethernet)
        RX packets 18345  bytes 19768910 (19.7 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 5065  bytes 398557 (398.5 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

enp0s8: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.0.2  netmask 255.255.252.0  broadcast 0.0.0.0
        inet6 fe80::a00:27ff:fe69:bb41  prefixlen 64  scopeid 0x20<link>
        ether 08:00:27:69:bb:41  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 13  bytes 1006 (1.0 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 32  bytes 3338 (3.3 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 32  bytes 3338 (3.3 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

Here we have "enp0s3" that links our VM to the Ethernet card of our PC; enp0s8 is the interface that link the host-a with the switch and "lo" is an imaginary interface, that is briefly, the local-host 

7. ```route -nve``` 

This command show on the terminal the routing table of the VM. This is an example of the command on host-a:

```
vagrant@host-a:~$ route -nve
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         10.0.0.1        0.0.0.0         UG        0 0          0 enp0s8
10.0.0.0        0.0.0.0         255.255.252.0   U         0 0          0 enp0s8
10.0.2.0        0.0.0.0         255.255.255.0   U         0 0          0 enp0s3
10.0.2.2        0.0.0.0         255.255.255.255 UH        0 0          0 enp0s3
```

8. ```ping "IPaddress"```

In this command you have to change "IPaddress" with the actual IP address of the interface you want to reach. For example if you want to ping host-c from host-a you have to type on terminal ```ping 10.0.8.2``` and this is the output:

```
vagrant@host-a:~$ ping 10.0.8.2
PING 10.0.8.2 (10.0.8.2) 56(84) bytes of data.
64 bytes from 10.0.8.2: icmp_seq=1 ttl=62 time=1.92 ms
64 bytes from 10.0.8.2: icmp_seq=2 ttl=62 time=1.53 ms
64 bytes from 10.0.8.2: icmp_seq=3 ttl=62 time=1.24 ms
64 bytes from 10.0.8.2: icmp_seq=4 ttl=62 time=1.38 ms
64 bytes from 10.0.8.2: icmp_seq=5 ttl=62 time=1.58 ms
64 bytes from 10.0.8.2: icmp_seq=6 ttl=62 time=1.67 ms
64 bytes from 10.0.8.2: icmp_seq=7 ttl=62 time=2.02 ms
^C
--- 10.0.8.2 ping statistics ---
7 packets transmitted, 7 received, 0% packet loss, time 6017ms
rtt min/avg/max/mdev = 1.249/1.624/2.021/0.261 ms
```

9. ```tcpdump -i "InterfaceName"```

In this command you have to change "InterfaceName" with the name of the interface where you want to sniff packets that are passing through it. In this example we ping host-c from host-a meanwhile switch, router-1 and router-2 are sniffing packets on enp0s8 and enp0s9:

![Tcpdump image](https://github.com/davideuez/dncs-lab/blob/master/screenshots/tcpdump.png)

10. ```curl 10.0.8.2```

From host-a or host-b you can retrieve data of a web-page (dustnic82/nginx-test) hosted in host-2-c that will be browsed on terminal. This is an example of the command on host-a:

```
vagrant@host-a:~$ curl 10.0.8.2
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

```

You can copy the text from **!DOCTYPE html** to **/html** and paste it on an editor. Then save the file with .html extension and open it with a browser (Google Chrome, Safari, Opera, ...)

# Members and repository information

This project for the course "Design of Networks and Communication System" was done by **Davide Uez** and **Luca Calearo**. 

We started the project by forking this repository: [https://github.com/dustnic/dncs-lab](https://github.com/dustnic/dncs-lab).
