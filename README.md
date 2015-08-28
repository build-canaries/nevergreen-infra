# Nevergreen Infra

These scripts are for recreating a nevergreen.io server which uses HTTPS.

It has only been tested on Ubuntu 14.04 x64.

There are four stages to the deployment of a new box:

* Bootstrap the box with Ansible and a deploy user
* As the deploy user set up the box with Nevergreen (haproxy, init.d scripts)
* Download the latest Nevergreen to the production directory

for security reasons the stages are broken up. You need to upload the SSL cetificates and set up the AES keys that Nevergreen uses to encrypt user passwords.

Once the scripts have run, nevevergreen can be run using an init.d script in /etc/init.d/nevergreen-production.

# Run Guide

## Bootstrap the box

```
ssh ubuntu@staging.nevergreen.io
wget https://raw.githubusercontent.com/build-canaries/nevergreen-infra/master/bootstrap.sh
sh bootstrap.sh
```

## Deploy the infrastructure

```
ssh deploy@staging.nevergreen.io
git clone https://github.com/build-canaries/nevergreen-infra.git

```
*Locally* copy the certificate (for nevergreen.io the cert is available from DNSimple).

```
scp certificate.pem deploy@staging.nevergreen.io:/home/deploy/nevergreen-infra/roles/proxy/templates/certificate.pem
```

Overwrite the AES key values.

```
vim /home/deploy/nevergreen-infra/staging
vim /home/deploy/nevergreen-infra/production
```

Run the ansible scripts to make the infra

```
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

# Deployment

From your ci server you can deploy a snapshot version of Nevergreen using

```
scp nevergreen-standalone.jar nevergreen@nevergreen.io:/home/nevergreen/deploy/staging
ssh nevergreen@nevergreen.io "sudo /etc/init.d/nevergreen-staging restart"
```

