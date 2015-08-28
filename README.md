# Nevergreen Infra

These scripts are for recreating a nevergreen.io server which uses HTTPS.

It has only been tested on Ubuntu 14.04 x64.

There are four stages to the deployment of a new box:

* Bootstrap the box with Ansible and a deploy user
* As the deploy user set up the box with Nevergreen dependencies (haproxy, java8)
* Configure an individual Nevergreen instance
* Install the latest Nevergreen to the production directory

Each section is broken up as you require a manual task to be performed after each for security reasons. You need to upload the SSL cetificates and set up the AES keys that Nevergreen uses to encrypt user passwords.

Once the scripts have run, nevevergreen can be run using an init.d script in /etc/init.d/nevergreen-production.

# Run Guide

## Bootstrap the box

```
ssh ubuntu@staging.nevergreen.io
wget https://raw.githubusercontent.com/build-canaries/nevergreen-infra/master/bootstrap.sh
sh bootstrap.sh
```

## Deploy the infrastructure

Please note you require the SSL certificate.pem (which is stored in DNSimple for nevergreen.io) for this step.

```
ssh deploy@staging.nevergreen.io
git clone https://github.com/build-canaries/nevergreen-infra.git
scp certificate.pem deploy@staging.nevergreen.io:/home/deploy/nevergreen-infra/roles/proxy/templates/certificate.pem
ssh deploy@staging.nevergreen.io
```

## Create Nevergreen Instances

The vim commands are there to remind you to add the AES_KEY over the placeholder value

```
vim /home/deploy/nevergreen-infra/staging
vim /home/deploy/nevergreen-infra/production
cd nevergreen-infra
ansible-playbook -i staging -c local appserver.yml
ansible-playbook -i production -c local appserver.yml
```

## Set up a production instance

You could do this via Snap.CI, but if you wanted to rerun it manually, you just need to download the jar.

```
ssh nevergreen@staging.nevergreen.io
cd deploy/production
wget https://github.com/build-canaries/nevergreen/releases/download/v0.7.0/nevergreen-standalone.jar
```
