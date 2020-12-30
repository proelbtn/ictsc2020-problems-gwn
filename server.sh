#!/bin/sh

sudo apt update

sudo apt install -y haproxy nginx

sudo mkdir -p /srv/ictsc2020/www

sudo sed -i "s/^RANDFILE/# RANDFILE/" /etc/ssl/openssl.cnf
sudo openssl genpkey -algorithm ec -pkeyopt ec_paramgen_curve:secp521r1 -out /srv/ictsc2020/server.key
sudo openssl req -new -x509 -key /srv/ictsc2020/server.key -subj "/CN=gwn.2020-final.ictsc.net" -out /srv/ictsc2020/server.pem

cat <<EOF | sudo tee /etc/nginx/sites-available/default
server {
        listen 443 ssl;
        listen [::]:443 ssl;

        server_name gwn.local;

        root /var/www/html;

        ssl_certificate /srv/ictsc2020/server.pem;
        ssl_certificate_key /srv/ictsc2020/server.key;

        location / {
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_pass http://localhost:8080/;
        }
}
EOF

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global                                                                                                             
        log /dev/log    local0                                                                                     
        log /dev/log    local1 notice                                                                              
        chroot /var/lib/haproxy                                                                                    
        stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners                              
        stats timeout 30s                                                                                          
        user haproxy                                                                                               
        group haproxy                                                                                              
        daemon                                                                                                     
                                                                                                                   
        # Default SSL material locations                                                                           
        ca-base /etc/ssl/certs                                                                                     
        crt-base /etc/ssl/private                                                                                  
                                                                                                                   
        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate             
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-S
HA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA2
56:DHE-RSA-AES256-GCM-SHA384                                                                                       
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256   
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets                                                

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

frontend websecure
        bind *:443 ssl crt /srv/ictsc2020/server.pem

        acl is_gwn_local hdr_end(host) -i gwn.local
        use_backend backend if is_gwn_local

backend backend
        server server 127.0.0.1:8080
EOF

cat <<EOF | sudo tee /srv/ictsc2020/www/index.html
<!DOCTYPE html>
<html>
<head>
	<title>Congraturations!</title>
</head>
<body>
	<h1>Congraturations!</h1>
</body>
</html>
EOF

cat <<EOF | sudo tee /srv/ictsc2020/webapp.service
[Unit]
Description=webapp
Wants=network.target
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server --bind 127.0.0.1 8080
WorkingDirectory=/srv/ictsc2020/www
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo ln -sf /srv/ictsc2020/webapp.service /etc/systemd/system

sudo systemctl disable nginx
sudo systemctl enable --now haproxy
sudo systemctl enable --now webapp

# sudo add-apt-repository ppa:vbernat/haproxy-2.2
# sudo apt-get install -y haproxy=2.2.\*
