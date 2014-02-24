FROM ubuntu
 
RUN echo 'deb http://archive.ubuntu.com/ubuntu precise main universe' > /etc/apt/sources.list && \
    echo 'deb http://archive.ubuntu.com/ubuntu precise-updates universe' >> /etc/apt/sources.list && \
    apt-get update

#Prevent daemon start during install
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -s /bin/true /sbin/initctl

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && mkdir -p /var/log/supervisor
CMD ["/usr/bin/supervisord", "-n"]

#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir /var/run/sshd && \
	echo 'root:root' |chpasswd

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y vim less net-tools inetutils-ping curl git telnet nmap socat dnsutils netcat tree htop unzip sudo

#Serf
RUN wget https://dl.bintray.com/mitchellh/serf/0.4.1_linux_amd64.zip && \
    unzip 0.4*.zip && \
    rm 0.4*.zip
RUN mv serf /usr/bin/

#Mesos Requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-setuptools python-protobuf default-jre python-pip sysklogd python-dev libcurl4-nss-dev libsasl2-dev
RUN pip install httpie

#Zookeeper
RUN curl -sSfL http://apache.mirrors.tds.net/zookeeper/zookeeper-3.4.5/zookeeper-3.4.5.tar.gz --output zookeeper.tar.gz && \
    tar xvf zookeeper.tar.gz && \
    rm zookeeper.tar.gz && \
    mv zookeeper* zookeeper

#Mesos 
RUN curl -sSfL http://downloads.mesosphere.io/master/ubuntu/12.04/mesos_0.17.0-rc1_amd64.deb --output mesos.deb && \
    dpkg -i mesos.deb && \
    rm mesos.deb
RUN curl -sSfL http://downloads.mesosphere.io/master/ubuntu/12.04/mesos_0.17.0-rc1_amd64.egg --output mesos.egg && \
    easy_install mesos.egg && \
    rm mesos.egg

#Marathon
RUN curl -sSfL http://downloads.mesosphere.io/marathon/marathon-0.4.0.tgz --output marathon.tgz && \
    tar xvf marathon.tgz && \
    rm marathon.tgz

#Docker
RUN mkdir -p /var/lib/mesos/executors && \
    cd /var/lib/mesos/executors && \
    curl -sSfL https://raw.github.com/mesosphere/mesos-docker/master/bin/mesos-docker --output docker
#Docker client only
RUN wget -O /usr/local/bin/docker https://get.docker.io/builds/Linux/x86_64/docker-latest && \
    chmod +x /usr/local/bin/docker

#Chronos
RUN curl -sSfL http://downloads.mesosphere.io/chronos/chronos-2.1.0_mesos-0.14.0-rc4.tgz --output chronos.tgz && \
    tar xvf chronos.tgz && \
    rm chronos.tgz

#Configuration

ADD . /docker
#RUN ln -s /docker/etc/supervisord-serf.conf /etc/supervisor/conf.d/supervisord-serf.conf
RUN ln -s /docker/etc/supervisord-ssh.conf /etc/supervisor/conf.d/supervisord-ssh.conf
RUN ln -s /docker/etc/supervisord-syslog.conf /etc/supervisor/conf.d/supervisord-syslog.conf
RUN ln -s /docker/etc/supervisord-zookeeper.conf /etc/supervisor/conf.d/supervisord-zookeeper.conf
RUN ln -s /docker/etc/zoo.cfg /zookeeper/conf/zoo.cfg
RUN ln -s /docker/etc/supervisord-master.conf /etc/supervisor/conf.d/supervisord-master.conf
RUN ln -s /docker/etc/supervisord-slave.conf /etc/supervisor/conf.d/supervisord-slave.conf
RUN ln -s /docker/etc/supervisord-marathon.conf /etc/supervisor/conf.d/supervisord-marathon.conf
RUN ln -s /docker/etc/supervisord-chronos.conf /etc/supervisor/conf.d/supervisord-chronos.conf
 
EXPOSE 22 5050 2181 8080 8081 7946
