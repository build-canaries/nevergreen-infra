#!/usr/bin/env bash

# Renew the certificate
certbot renew --force-renewal

# Concatenate new cert files
cat /etc/letsencrypt/live/nevergreen/fullchain.pem /etc/letsencrypt/live/nevergreen/privkey.pem > /etc/haproxy/certs/nevergreen.io.pem

# Reload HAProxy
serivce haproxy restart
