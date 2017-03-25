#!/bin/bash -v
            sudo apt-get update
            #make instance reachable via ssh key
            echo "ssh-rsa YOUR-PUBLIC-SSH-KEY" >> /root/.ssh/authorized_keys
            #Install Java Silently
            sudo apt-get install -y python-software-properties debconf-utils
            sudo add-apt-repository -y ppa:webupd8team/java
            sudo apt-get update
            echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
            sudo apt-get install -y oracle-java8-installer

            
            #Install ES
            wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
            sudo apt-get install -y apt-transport-https
            echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
            sudo apt-get -y update && sudo apt-get install -y elasticsearch
            sudo update-rc.d elasticsearch defaults 95 10
            sudo -i service elasticsearch start
            #Sequential deploy with Heat dependencies
            if [ hostname == "es01" ]
                then
                     node01=$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g) # ip della macchina "127.0.0.1"
                     node02=$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g  | awk -F'.' '{ print $1"."$2"."$3"."$4+1 }')
                     node03=$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g  | awk -F'.' '{ print $1"."$2"."$3"."$4+2 }')
            fi
            sudo sed -i 's/#discovery.zen.ping.unicast.hosts: ["host1"."host2"]/discovery.zen.ping.unicast.hosts: [ "127.0.0.1","'$node01'","'$node02'","'$node03'" ]/g' /etc/elasticsearch/elasticsearch.yml
            sudo sed -i "s/#cluster.name: my-application/cluster.name: es-cluster/g" /etc/elasticsearch/elasticsearch.yml
            sudo sed -i "s/#network.host: *.*.*.*/network.host: "$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g)"/g" /etc/elasticsearch/elasticsearch.yml
            sudo sed -i "s/#node.name: node-1/node.name: "$(hostname)"/g" /etc/elasticsearch/elasticsearch.yml
            sudo service elasticsearch restart
