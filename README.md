ssh root@staging.nevergreen.io
wget https://raw.githubusercontent.com/build-canaries/nevergreen-infra/master/bootstrap_root.sh
sh bootstrap_root.sh

ssh deploy@staging.nevergreen.io
git clone https://github.com/build-canaries/nevergreen-infra.git
scp certificate.pem deploy@staging.nevergreen.io:/home/deploy/nevergreen-infra/roles/proxy/templates/certificate.pem
ssh deploy@staging.nevergreen.io

# add AES key: http://www.cryptool-online.org/index.php?option=com_cto&view=tool&Itemid=136&lang=en
vim /home/deploy/nevergreen-infra/staging
vim /home/deploy/nevergreen-infra/production

ansible-playbook -i staging -c local appserver.yml
ansible-playbook -i production -c local appserver.yml