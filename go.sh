#!/bin/bash

set -e
set -x

SERVER="35.176.150.70"
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
    ssh $REMOTE "sudo apt-get update"
    ssh $REMOTE "sudo apt-get install haproxy default-jre -y" # need to make this explicit about java8
}

function setup_haproxy {
    scp haproxy.cfg $REMOTE:/tmp/haproxy.cfg
    ssh $REMOTE "sudo cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg"
    ssh $REMOTE "sudo service haproxy restart"
}

function download_nevergreen {
    ssh $REMOTE "sudo mkdir -p /home/nevergreen/deploy/production"
    ssh $REMOTE "sudo mkdir -p /home/nevergreen/deploy/staging"
    
    # Use v1.0.0 - we want to override this with the latest (or figure out how to get that here)
    ssh $REMOTE "sudo wget https://github.com/build-canaries/nevergreen/releases/download/v1.0.0/nevergreen-standalone.jar -P /tmp"
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

setup_github_keys_for_ssh
create_deployment_user
install_java_and_haproxy
setup_haproxy
download_nevergreen
create_service_to_run_nevergreen
