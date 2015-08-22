# works on Ubuntu 14.04 x64

ssh root@staging.nevergreen.io
wget https://raw.githubusercontent.com/build-canaries/nevergreen-infra/master/bootstrap.sh
sh bootstrap.sh

ssh deploy@staging.nevergreen.io
git clone https://github.com/build-canaries/nevergreen-infra.git
scp certificate.pem deploy@staging.nevergreen.io:/home/deploy/nevergreen-infra/roles/proxy/templates/certificate.pem
ssh deploy@staging.nevergreen.io

# add AES key: y4tgxn5ClgTlCYbS : http://www.cryptool-online.org/index.php?option=com_cto&view=tool&Itemid=136&lang=en
vim /home/deploy/nevergreen-infra/staging
vim /home/deploy/nevergreen-infra/production
cd nevergreen-infra
ansible-playbook -i staging -c local appserver.yml
ansible-playbook -i production -c local appserver.yml

ssh nevergreen@staging.nevergreen.io
cd deploy/production
wget https://github.com/build-canaries/nevergreen/releases/download/v0.7.0/nevergreen-standalone.jar