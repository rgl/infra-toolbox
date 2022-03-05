ENV['VAGRANT_EXPERIMENTAL'] = 'typed_triggers'

require './lib.rb'

# get the docker hub auth from the host ~/.docker/config.json file.
DOCKER_HUB_AUTH = get_docker_hub_auth

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu-20.04-amd64'
  #config.vm.box = 'ubuntu-20.04-uefi-amd64'

  config.vm.hostname = 'infra-toolbox.test'

  config.vm.provider 'libvirt' do |lv, config|
    lv.memory = 2048
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    lv.nested = true # nested virtualization.
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider 'virtualbox' do |vb, config|
    vb.linked_clone = true
    vb.memory = 2048
    vb.cpus = 2
  end

  config.vm.provider 'hyperv' do |hv, config|
    hv.vmname = File.basename(File.dirname(__FILE__))
    hv.linked_clone = true
    hv.memory = 2048
    hv.cpus = 2
    hv.enable_virtualization_extensions = true # nested virtualization.
    hv.vlan_id = ENV['HYPERV_VLAN_ID']
    # see https://github.com/hashicorp/vagrant/issues/7915
    # see https://github.com/hashicorp/vagrant/blob/10faa599e7c10541f8b7acf2f8a23727d4d44b6e/plugins/providers/hyperv/action/configure.rb#L21-L35
    config.vm.network :private_network, bridge: ENV['HYPERV_SWITCH_NAME'] if ENV['HYPERV_SWITCH_NAME']
    config.vm.synced_folder '.', '/vagrant',
      type: 'smb',
      smb_username: ENV['VAGRANT_SMB_USERNAME'] || ENV['USER'],
      smb_password: ENV['VAGRANT_SMB_PASSWORD']
    # configure our hyper-v vm.
    config.trigger.before :'VagrantPlugins::HyperV::Action::StartInstance', type: :action do |trigger|
      trigger.ruby do |env, machine|
        system(
          'PowerShell',
          '-NoLogo',
          '-NoProfile',
          '-NonInteractive',
          '-ExecutionPolicy',
          'Bypass',
          '-Command',
          <<~COMMAND
            $vmName = '#{machine.provider_config.vmname}'
            # enable all the integration services.
            # NB because, for some reason, sometimes "Guest Service Interface" is not enabled.
            Get-VMIntegrationService $vmName | Enable-VMIntegrationService
            # boot from the first hard-disk.
            # NB without this, it will waste time trying to boot from DVD and Network.
            $bootOrder = @(Get-VMHardDiskDrive $vmName | Select-Object -First 1)
            Set-VMFirmware $vmName -BootOrder $bootOrder
          COMMAND
        )
      end
    end
  end

  config.vm.provider 'vsphere' do |vsphere, override|
    vsphere.name = ENV['VSPHERE_VM_NAME']
    vsphere.notes = "Created from #{__FILE__}"
    vsphere.cpu_count = 2
    vsphere.memory_mb = 2*1024
    vsphere.user = ENV['GOVC_USERNAME']
    vsphere.password = ENV['GOVC_PASSWORD']
    vsphere.insecure = true
    vsphere.host = ENV['GOVC_HOST']
    vsphere.data_center_name = ENV['GOVC_DATACENTER']
    vsphere.compute_resource_name = ENV['GOVC_CLUSTER']
    vsphere.data_store_name = ENV['GOVC_DATASTORE']
    vsphere.template_name = ENV['VSPHERE_TEMPLATE_NAME']
    vsphere.vm_base_path = ENV['VSPHERE_VM_FOLDER']
    vsphere.vlan = ENV['VSPHERE_VLAN']
    if ENV['VAGRANT_SMB_PASSWORD']
      override.vm.synced_folder '.', '/vagrant',
        type: 'smb',
        smb_host: ENV['VAGRANT_SMB_HOST'],
        smb_username: ENV['VAGRANT_SMB_USERNAME'] || ENV['USER'],
        smb_password: ENV['VAGRANT_SMB_PASSWORD']
    end
  end

  config.vm.provision :shell, inline: 'cloud-init status --long --wait', name: 'wait for cloud-init to finish'
  config.vm.provision :shell, path: 'provision-ansible.sh', name: 'ansible'
  config.vm.provision :shell, path: 'provision.sh', name: 'ansible playbook'
  config.vm.provision :shell, path: 'provision-docker-hub-auth.sh', env: {'DOCKER_HUB_AUTH' => DOCKER_HUB_AUTH} if DOCKER_HUB_AUTH
  config.vm.provision :shell, path: 'provision-docker-compose.sh'
  config.vm.provision :shell, path: 'provision-powershell.sh'
  config.vm.provision :shell, path: 'provision-packer.sh'
  config.vm.provision :shell, path: 'provision-terraform.sh'
  config.vm.provision :shell, path: 'provision-kubectl.sh'
  config.vm.provision :shell, path: 'provision-helm.sh'
  config.vm.provision :shell, path: 'provision-k9s.sh'
  config.vm.provision :shell, path: 'provision-azure-cli.sh'
  config.vm.provision :shell, path: 'provision-govc.sh'
  config.vm.provision :shell, path: 'provision-ovftool.sh'
  config.vm.provision :shell, path: 'provision-vmware-powercli.sh'
  config.vm.provision :shell, path: 'provision-vagrant.sh'
end
