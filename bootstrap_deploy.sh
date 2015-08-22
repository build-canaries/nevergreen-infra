git clone https://github.com/build-canaries/nevergreen-infra.git

echo "copy the security keys to nevergreen-infra/roles/proxy/templates/certificate.pem"
echo "add the aes_keys to nevergreen-infra/hosts"
echo "run with: ansible-playbook -i hosts -c local appserver.yml"
