FROM ubuntu:13.10
 
RUN apt-get update

#Runit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo

#Mesos Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y zookeeperd default-jre python-setuptools python-protobuf

#Zookeeper
RUN curl http://www.us.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz | tar xz
RUN mv zookeeper* zookeeper

#Mesos 
RUN curl -sSfL http://downloads.mesosphere.io/master/ubuntu/13.10/mesos_0.18.2_amd64.deb --output mesos.deb && \
    dpkg -i mesos.deb && \
    rm mesos.deb
RUN curl -sSfL http://downloads.mesosphere.io/master/ubuntu/13.10/mesos_0.18.2_amd64.egg --output mesos.egg && \
    easy_install mesos.egg && \
    rm mesos.egg

#Marathon
RUN curl -sSfL http://downloads.mesosphere.io/marathon/marathon-0.5.0/marathon-0.5.0.tgz | tar xz 
RUN mv marathon* marathon

#Docker
RUN mkdir -p /var/lib/mesos/executors && \
    cd /var/lib/mesos/executors && \
    curl -sSfL https://raw.github.com/mesosphere/mesos-docker/master/bin/mesos-docker --output docker
#Docker client only
RUN wget -O /usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-latest && \
    chmod +x /usr/local/bin/docker

#Chronos
RUN curl -sSfL http://downloads.mesosphere.io/chronos/chronos-2.1.0_mesos-0.14.0-rc4.tgz | tar xz
#RUN mv chronos* chronos

#Add runit services
ADD sv /etc/service 

ADD etc/zoo.cfg /zookeeper/conf/zoo.cfg

EXPOSE 22 5050 2181 8080 8081 7946
