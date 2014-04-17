FROM ubuntu
 
RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main universe' > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu precise-updates main universe' >> /etc/apt/sources.list && \
    apt-get update

#Runit
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y runit 
CMD /usr/sbin/runsvdir-start

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo

#Mesos Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-setuptools python-protobuf default-jre python-pip sysklogd python2.7-dev libcurl4-nss-dev libsasl2-dev
RUN pip install httpie

#Zookeeper
RUN curl -sSfL http://apache.mirrors.tds.net/zookeeper/zookeeper-3.4.5/zookeeper-3.4.5.tar.gz | tar xz && \ 
    mv zookeeper* zookeeper

#Mesos 
RUN curl -sSfL http://downloads.mesosphere.io/master/ubuntu/12.04/mesos_0.18.0_amd64.deb --output mesos.deb && \
    dpkg -i mesos.deb && \
    rm mesos.deb
RUN curl -sSfL http://downloads.mesosphere.io/master/ubuntu/12.04/mesos_0.18.0_amd64.egg --output mesos.egg && \
    easy_install mesos.egg && \
    rm mesos.egg

#Marathon
RUN curl -sSfL http://downloads.mesosphere.io/marathon/marathon-0.4.1.tgz | tar xz 

#Docker
RUN mkdir -p /var/lib/mesos/executors && \
    cd /var/lib/mesos/executors && \
    curl -sSfL https://raw.github.com/mesosphere/mesos-docker/master/bin/mesos-docker --output docker
#Docker client only
RUN wget -O /usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-latest && \
    chmod +x /usr/local/bin/docker

#Chronos
RUN curl -sSfL http://downloads.mesosphere.io/chronos/chronos-2.1.0_mesos-0.14.0-rc4.tgz | tar xz

#Configuration
ADD . /docker

#Runit Automatically setup all services in the sv directory
RUN for dir in /docker/sv/*; do echo $dir; chmod +x $dir/run $dir/log/run; ln -s $dir /etc/service/; done

RUN ln -s /docker/etc/zoo.cfg /zookeeper/conf/zoo.cfg

ENV HOME /root
WORKDIR /root

EXPOSE 22 5050 2181 8080 8081 7946
