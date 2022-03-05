# About

This is a vagrant environment for launching infrastructure using:

* Packer
* Terraform
* Ansible
* Vagrant
* Helm
* Kubectl

In:

* Azure
* VMware vSphere

And, using nested virtualization, in:

* KVM/libvirt

# Usage

See the [rgl/ubuntu-vagrant repository](https://github.com/rgl/ubuntu-vagrant) to known how to launch this environment using vagrant.

Then follow one of the next sections example to known how to manage a remote machine using this environment tools.

## Ansible Ubuntu Example

Enter the vagrant environment:

```bash
vagrant ssh
```

Create an example inventory and playbook:

```bash
mkdir ubuntu-example
cd ubuntu-example
cat >inventory.yml <<'EOF'
all:
  children:
    example:
      hosts:
        192.168.192.123:
  vars:
    # connection configuration.
    # see https://docs.ansible.com/ansible-core/2.12/collections/ansible/builtin/ssh_connection.html
    ansible_user: vagrant
    ansible_password: vagrant
EOF
cat >ansible.cfg <<'EOF'
[defaults]
inventory = inventory.yml
stdout_callback = community.general.yaml
host_key_checking = False # NB only do this in test scenarios.
EOF
cat >playbook.yml <<'EOF'
- hosts: example
  gather_facts: no
  become: yes
  tasks:
    - name: Update APT cache
      apt:
        update_cache: yes
        cache_valid_time: 10800 # 3h
      changed_when: false
    - name: Install tcpdump
      apt:
        name: tcpdump
EOF
```

Kick the tires:

```bash
ansible-inventory --list --yaml
ansible -m ping all
ansible -m gather_facts all
ansible -m command -a 'id' all
```

Run the playbook:

```bash
ansible-playbook playbook.yml #-vvv
```

## Ansible Windows Example

Enter the vagrant environment:

```bash
vagrant ssh
```

Create an example inventory and playbook:

```bash
mkdir windows-example
cd windows-example
cat >inventory.yml <<'EOF'
all:
  children:
    example:
      hosts:
        192.168.192.123:
  vars:
    # connection configuration.
    # see https://github.com/rgl/terraform-libvirt-ansible-windows-example/blob/master/README.md#windows-management
    # see https://docs.ansible.com/ansible-core/2.12/collections/ansible/builtin/psrp_connection.html
    ansible_user: vagrant
    ansible_password: vagrant
    ansible_connection: psrp
    ansible_psrp_protocol: http
    ansible_psrp_message_encryption: never
    ansible_psrp_auth: credssp
    # NB ansible does not yet support PowerShell 7.
    #ansible_psrp_configuration_name: PowerShell.7 
EOF
cat >ansible.cfg <<'EOF'
[defaults]
inventory = inventory.yml
stdout_callback = community.general.yaml
EOF
cat >playbook.yml <<'EOF'
- hosts: example
  gather_facts: no
  tasks:
    - name: Install Chocolatey
      chocolatey.chocolatey.win_chocolatey:
        name: chocolatey
    - name: Install Notepad3
      chocolatey.chocolatey.win_chocolatey:
        name: notepad3
EOF
```

Kick the tires:

```bash
ansible-inventory --list --yaml
ansible -m win_ping all
ansible -m gather_facts all
ansible -m win_command -a 'whoami /all' all
ansible -m win_shell -a '$PSVersionTable' all
ansible -m win_shell -a 'Get-PSSessionConfiguration' all
```

Run the playbook:

```bash
ansible-playbook playbook.yml #-vvv
```

## Example Repositories

* Packer/Ansible/Debian/Windows:
  * https://github.com/rgl/packer-qemu-ansible-debian-example
  * https://github.com/rgl/packer-qemu-ansible-windows-example
  * https://github.com/rgl/debian-router-ansible-vagrant
  * https://github.com/rgl/windows-router-ansible-vagrant
* Azure:
  * https://github.com/rgl/terraform-ansible-azure-vagrant
  * https://github.com/rgl/terraform-azure-container-instances-vagrant
  * https://github.com/rgl/terraform-azure-aks-example
  * https://github.com/rgl/azure-ubuntu-vm
  * https://github.com/rgl/azure-windows-vm
  * https://github.com/rgl/azure-vpn-gateway-example
* VMware vSphere:
  * https://github.com/rgl/terraform-vsphere-ubuntu-example
  * https://github.com/rgl/terraform-vsphere-windows-example
* KVM/libvirt:
  * https://github.com/rgl/debian-vagrant
  * https://github.com/rgl/ubuntu-vagrant
  * https://github.com/rgl/windows-vagrant
