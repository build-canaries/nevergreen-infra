#!/bin/bash

set -e
set -x

SERVER="35.176.75.186"
REMOTE="ubuntu@$SERVER"
AWS_KEY_LOCATION="~/.ssh/london-amazon.pem"

function setup_github_keys_for_ssh {
    ssh -i $AWS_KEY_LOCATION $REMOTE "curl https://github.com/joejag.keys >> ~/.ssh/authorized_keys"
    ssh -i $AWS_KEY_LOCATION $REMOTE "curl https://github.com/GentlemanHal.keys >> ~/.ssh/authorized_keys"
}

function create_deployment_user {
    # Create user
    ssh $REMOTE "sudo adduser --disabled-password --gecos '' nevergreen"
    # Give user sudo access
    ssh $REMOTE "sudo usermod -aG sudo nevergreen"

    ssh $REMOTE "sudo mkdir /home/nevergreen/.ssh"
    ssh $REMOTE "sudo touch /home/nevergreen/.ssh/authorized_keys"
    ssh $REMOTE "sudo chown -R nevergreen:nevergreen /home/nevergreen/.ssh"
    ssh $REMOTE "sudo sh -c 'curl https://github.com/joejag.keys >> /home/nevergreen/.ssh/authorized_keys'"
    ssh $REMOTE "sudo sh -c 'curl https://github.com/GentlemanHal.keys >> /home/nevergreen/.ssh/authorized_keys'"

    ssh nevergreen@$SERVER "ssh-keygen -f /home/nevergreen/.ssh/id_rsa -t rsa -N ''"
    ssh nevergreen@$SERVER "cat /home/nevergreen/.ssh/id_rsa"
    ssh nevergreen@$SERVER "cat /home/nevergreen/.ssh/id_rsa.pub >> /home/nevergreen/.ssh/authorized_keys"
}

function install_java_and_haproxy {
    ssh $REMOTE "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9"
    ssh $REMOTE "sudo apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main'"
    ssh $REMOTE "sudo apt-get update"
    ssh $REMOTE "sudo apt-get install zulu19 -y"

    ssh $REMOTE "sudo apt-get install haproxy -y"
}

function setup_haproxy {
    scp haproxy.cfg $REMOTE:/tmp/haproxy.cfg
    ssh $REMOTE "sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg"
}

function download_nevergreen {
    ssh $REMOTE "sudo mkdir -p /home/nevergreen/deploy/production"
    ssh $REMOTE "sudo mkdir -p /home/nevergreen/deploy/staging"

    # Use v3.0.0 - we want to override this with the latest (or figure out how to get that here)
    ssh $REMOTE "sudo wget https://github.com/build-canaries/nevergreen/releases/download/v6.0.0/nevergreen-standalone.jar -P /tmp"
    ssh $REMOTE "sudo cp /tmp/nevergreen-standalone.jar /home/nevergreen/deploy/production"
    ssh $REMOTE "sudo cp /tmp/nevergreen-standalone.jar /home/nevergreen/deploy/staging"
    ssh $REMOTE "sudo chown -R nevergreen:nevergreen /home/nevergreen/deploy/"
}

function create_service_to_run_nevergreen {
    scp *.service $REMOTE:/tmp
    ssh $REMOTE "sudo mv /tmp/*.service /etc/systemd/system/"

    # Tells systemd that we new services
    ssh $REMOTE "sudo systemctl daemon-reload"
    ssh $REMOTE "sudo systemctl restart nevergreen-production-1.service"
    ssh $REMOTE "sudo systemctl restart nevergreen-production-2.service"
    ssh $REMOTE "sudo systemctl restart nevergreen-staging-1.service"

    # Give sudo access to nevergreen user to restart the services (rather than giving nevergreen sudo to everything)
    echo '%nevergreen ALL=NOPASSWD: /bin/systemctl * nevergreen-staging-1' | ssh $REMOTE "sudo EDITOR='tee -a' visudo"
    echo '%nevergreen ALL=NOPASSWD: /bin/systemctl * nevergreen-production-1' | ssh $REMOTE "sudo EDITOR='tee -a' visudo"
    echo '%nevergreen ALL=NOPASSWD: /bin/systemctl * nevergreen-production-2' | ssh $REMOTE "sudo EDITOR='tee -a' visudo"
}

function setup_certbot {
    ssh $REMOTE "sudo snap install core; sleep 1; sudo snap refresh core"
    ssh $REMOTE "sudo snap install --classic certbot"
    ssh $REMOTE "sudo ln -s /snap/bin/certbot /usr/bin/certbot"
    ssh $REMOTE "sudo certbot certonly --standalone --noninteractive --agree-tos --email joe@joejag.com --cert-name nevergreen -d nevergreen.io -d staging.nevergreen.io"
    ssh $REMOTE "sudo mkdir /etc/haproxy/certs"
    ssh $REMOTE "sudo -E bash -c 'cat /etc/letsencrypt/live/nevergreen/fullchain.pem /etc/letsencrypt/live/nevergreen/privkey.pem > /etc/haproxy/certs/nevergreen.io.pem'"
    ssh $REMOTE "sudo service haproxy restart"

    # setup cron job to update certs
    ssh $REMOTE "sudo systemctl enable cron"
    scp update-certs.sh $REMOTE:/tmp/update-certs.sh
    ssh $REMOTE "sudo cp /tmp/update-certs.sh /root/update-certs.sh"
    ssh $REMOTE "sudo chmod +x /root/update-certs.sh"
    # “At 00:00 on every 7th day-of-month from 1 through 28.”
    ssh $REMOTE "echo '0 0 1-28/7 * * /root/update-certs.sh' | sudo crontab -"
}

setup_github_keys_for_ssh
create_deployment_user
install_java_and_haproxy
setup_haproxy
download_nevergreen
create_service_to_run_nevergreen
setup_certbot
