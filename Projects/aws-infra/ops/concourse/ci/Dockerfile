FROM debian:latest

RUN apt-get update
RUN apt-get install -y wget jq python-pip
RUN wget https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/1.5.3/credhub-linux-1.5.3.tgz && tar xvf credhub-linux-1.5.3.tgz -C /usr/local/bin
RUN pip install awscli
