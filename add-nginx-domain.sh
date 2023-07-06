#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 domain port"
    exit 1
fi

domain="$1"
port="$2"

# Configuration file name
config_file="/etc/nginx/sites-available/$domain"

# Check if the file already exists
if [ -f "$config_file" ]; then
    echo "The configuration file $config_file already exists."
    exit 1
fi

certbot certonly --standalone --preferred-challenges http -d $domain

# Create the configuration file
cat > "$config_file" <<EOF
server {
    server_name $domain;

    location / {
        proxy_pass http://localhost:$port;
        include /etc/nginx/proxy_params;
    }

    listen 443 ssl; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}

server {
    if (\$host = $domain) {
        return 301 https://\$host\$request_uri;
    } # managed by Certbot

    listen 80;
    server_name $domain;
    return 404; # managed by Certbot
}
EOF

ln -s $config_file /etc/nginx/sites-enabled/

echo "The configuration file $config_file has been created successfully in sites-available."

echo "Restarting Nginx"

service nginx restart

service nginx status
