#!/bin/bash

# Update nginx to match worker_processes to no. of cpu's
procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes  1/worker_processes $procs/" /etc/nginx/nginx.conf

# Always chown webroot for better mounting
mkdir -p /usr/share/nginx_stats
chown -Rf nginx:nginx /usr/share/nginx_stats /usr/share/nginx

# Start supervisord and services
/usr/local/bin/supervisord -c /etc/supervisor.conf

