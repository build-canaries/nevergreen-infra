apt-get install software-properties-common -y
apt-add-repository ppa:ansible/ansible -y
apt-get update
apt-get install python-pycurl ansible git zip unzip -y

echo "---
- hosts: all
  tasks:
    - user: name=deploy groups=sudo
    - user: name=nevergreen
    - authorized_key: user=deploy key=https://github.com/joejag.keys
    - authorized_key: user=nevergreen key=https://github.com/joejag.keys
    - name: Allow passwordles sudo
      lineinfile: \"dest=/etc/sudoers state=present regexp='^%sudo' line='%sudo ALL=(ALL) NOPASSWD: ALL'\"
    - name: Disallow root SSH access
      action: lineinfile dest=/etc/ssh/sshd_config regexp=\"^PermitRootLogin\" line=\"PermitRootLogin no\" state=present 
      notify: Restart sshd

  handlers:
    - name: Restart ssh
      action: service ssh state=restarted" > user.yml


ansible-playbook -i "localhost," -c local user.yml