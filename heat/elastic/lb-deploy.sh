#!/bin/bash -v
            sudo apt-get update
            #make instance reachable via ssh key
            echo "ssh-rsa YOUR-PUBLIC-SSH-KEY
" >> /root/.ssh/authorized_keys
            sudo apt-get install -y haproxy
            # HA Proxy conf
            echo "
listen kibana "$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g  | awk -F'.' '{ print $1"."$2"."$3"."$4 }')":80
        balance roundrobin
        mode tcp
        option tcpka
        server kibana 127.0.0.1:5601 check weight 1        
listen elastic 127.0.0.1:9200
        balance roundrobin
        mode tcp
        option tcpka
        server es01 "$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g  | awk -F'.' '{ print $1"."$2"."$3"."$4+1 }')":9200 check weight 1
        server es02 "$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g  | awk -F'.' '{ print $1"."$2"."$3"."$4+2 }')":9200 check weight 1
        server es03 "$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g  | awk -F'.' '{ print $1"."$2"."$3"."$4+3 }')":9200 check weight 1
" >> /etc/haproxy/haproxy.cfg
            #
            sudo sed -i "s/ENABLED=0/ENABLED=1/g" /etc/default/haproxy
            sudo service haproxy start
            
            #Install kibana
            wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
            sudo apt-get install -y apt-transport-https
            echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
            sudo apt-get update && sudo apt-get install -y kibana
            sudo sed -i 's/#server.host: "localhost"/server.host: "$(ifconfig | grep "inet addr" | head -n1 | awk '{ print $2 }' | sed s'/addr://'g  | awk -F'.' '{ print $1"."$2"."$3"."$4+1 }')"/g' /etc/kibana/kibana.yml
            #sudo sed -i 's/#server.port: 5601/server.port: 80/g' /etc/kibana/kibana.yml
            service kibana restart
