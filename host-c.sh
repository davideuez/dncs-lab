export DEBIAN_FRONTEND=noninteractive

sudo su
apt-get update

# install docker and curl
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

# first clean and then run docker image "dustnic82/nginx-test"
docker system prune -a
docker run --name DNCSWebserver -p 80:80 -d dustnic82/nginx-test

# adds IP address to the interface and set it "up"
ip add add 10.0.8.2/24 dev enp0s8
ip link set enp0s8 up


# Both lines are used to create static routes to reach subnet "Hosts-A" and "Hosts-B" via router-2
ip route add 10.0.0.0/22 via 10.0.8.1
ip route add 10.0.4.0/24 via 10.0.8.1