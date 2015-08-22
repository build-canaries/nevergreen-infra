git clone https://github.com/build-canaries/nevergreen-infra.git

echo "copy the security keys to roles/proxy/templates/certificate.pem"
echo "add the aes_keys to hosts"
echo "run with: ansible-playbook -i `"localhost,`" -c local main.yml"
