#!/bin/bash

echo "Enter ip1: "
read ip1

echo "Enter ip2: "
read ip2

echo "Enter ip3 (observer): "
read ip3

cat > ./inventory.txt <<EOL
[servers]
ansible-target-1 ansible_host=$ip1 ansible_connection=ssh ansible_user=ubuntu
ansible-target-2 ansible_host=$ip2 ansible_connection=ssh ansible_user=ubuntu
ansible-target-3 ansible_host=$ip3 ansible_connection=ssh ansible_user=ubuntu

[target]
ansible-target-1
ansible-target-2
ansible-target-3

[observer]
ansible-target-3
EOL


cat > ./roles/observer/files/grafana/provisioning/datasources/all.yml <<EOL
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://$ip3
    # observer ip
EOL

cat > ./roles/observer/files/prometheus_main.yml <<EOL
scrape_configs:
  - job_name: prometheus
    scrape_interval: 30s
    static_configs:
    - targets: ["localhost:9090"]

  - job_name: node-exporter
    scrape_interval: 30s
    static_configs:
    - targets: ["$ip1:9100", "$ip2:9100", "$ip3:9100"]

  - job_name: cadvisor
    scrape_interval: 30s
    static_configs:
    - targets: ["$ip2:9101", "$ip3:9101"]

EOL

echo "Done"