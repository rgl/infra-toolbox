ENV['VAGRANT_EXPERIMENTAL'] = 'typed_triggers'

VAGRANT_USERNAME = 'vagrant'
VAGRANT_PASSWORD = 'abracadabra'

require './lib.rb'

# get the docker hub auth from the host ~/.docker/config.json file.
DOCKER_HUB_AUTH = get_docker_hub_auth

cloud_init_network_config = {
  # Uncomment these properties to configure a static IP address.
  # 'version' => 2,
  # 'ethernets' => {
  #   'eth0' => {
  #     'dhcp4' => false,
  #     'addresses' => [
  #       '10.0.0.123/24',
  #     ],
  #     'gateway4' => '10.0.0.1',
  #     'nameservers' => {
  #       'addresses' => [
  #         '10.0.0.1',
  #       ],
  #     },
  #   },
  # },
}

cloud_init_user_data = {
  # modify the provisioning user credentials.
  'users' => [
    {
      'name' => VAGRANT_USERNAME,
      'plain_text_passwd' => VAGRANT_PASSWORD,
      'lock_passwd' => false,
    },
  ],
  # NB the runcmd output is written to journald and /var/log/cloud-init-output.log.
  'runcmd' => [
    "echo '************** DONE RUNNING CLOUD-INIT **************'",
  ],
}

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu-20.04-amd64'
  #config.vm.box = 'ubuntu-20.04-uefi-amd64'

  config.vm.hostname = 'infra-toolbox.test'

  # use the credentials defined in cloud_init_user_data.
  config.ssh.username = VAGRANT_USERNAME
  config.ssh.password = VAGRANT_PASSWORD

  config.vm.provider 'libvirt' do |lv, config|
    lv.memory = 2048
    lv.cpus = 2
    lv.cpu_mode = 'host-passthrough'
    lv.nested = true # nested virtualization.
    lv.keymap = 'pt'
    lv.storage :file, :device => :cdrom, :path => create_cloud_init_iso_trigger(config, 'kvm', cloud_init_user_data, cloud_init_network_config)
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider 'virtualbox' do |vb, config|
    vb.linked_clone = true
    vb.memory = 2048
    vb.cpus = 2
    vb.customize [
      'storageattach', :id,
      '--storagectl', 'SATA Controller',
      '--device', 0,
      '--port', 1,
      '--type', 'dvddrive',
      '--medium', create_cloud_init_iso_trigger(config, nil, cloud_init_user_data, cloud_init_network_config)]
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
    # add the cloud-init data iso to the hyperv vm.
    config.trigger.before :'VagrantPlugins::HyperV::Action::StartInstance', type: :action do |trigger|
      trigger.ruby do |env, machine|
        create_cloud_init_iso('tmp/cidata.iso', env, config, nil, cloud_init_user_data, cloud_init_network_config)
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
            # attach the cloud-init data iso.
            $drive = @(Get-VMDvdDrive $vmName | Where-Object {$_.Path -like '*cidata.iso'})
            if (!$drive) {
              Write-Host 'Adding the cidata.iso DVD to the VM...'
              Add-VMDvdDrive $vmName -Path $PWD/tmp/cidata.iso
            }
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
    # NB the extra_config data ends-up inside the VM .vmx file.
    # NB the guestinfo properties will be exposed by cloud-init-vmware-guestinfo
    #    as a cloud-init datasource.
    # See https://github.com/vmware/cloud-init-vmware-guestinfo
    vsphere.extra_config = {
      'guestinfo.metadata' => gzip_base64({
        'network' => gzip_base64(cloud_init_network_config.to_json),
        'network.encoding' => 'gzip+base64',
      }.to_json),
      'guestinfo.metadata.encoding' => 'gzip+base64',
      'guestinfo.userdata' => gzip_base64("#cloud-config\n#{cloud_init_user_data.to_json}"),
      'guestinfo.userdata.encoding' => 'gzip+base64',
    }
    if ENV['VAGRANT_SMB_PASSWORD']
      override.vm.synced_folder '.', '/vagrant',
        type: 'smb',
        smb_host: ENV['VAGRANT_SMB_HOST'],
        smb_username: ENV['VAGRANT_SMB_USERNAME'] || ENV['USER'],
        smb_password: ENV['VAGRANT_SMB_PASSWORD']
    end
  end

  config.vm.provision :shell, inline: 'cloud-init status --long --wait', name: 'wait for cloud-init to finish'
  config.vm.provision :shell, path: 'provision-base.sh'
  config.vm.provision :shell, path: 'provision-docker.sh'
  config.vm.provision :shell, path: 'provision-docker-hub-auth.sh', env: {'DOCKER_HUB_AUTH' => DOCKER_HUB_AUTH} if DOCKER_HUB_AUTH
  config.vm.provision :shell, path: 'provision-docker-compose.sh'
  config.vm.provision :shell, path: 'provision-powershell.sh'
  config.vm.provision :shell, path: 'provision-ansible.sh'
  config.vm.provision :shell, path: 'provision-packer.sh'
  config.vm.provision :shell, path: 'provision-terraform.sh'
  config.vm.provision :shell, path: 'provision-kubectl.sh'
  config.vm.provision :shell, path: 'provision-helm.sh'
  config.vm.provision :shell, path: 'provision-k9s.sh'
  config.vm.provision :shell, path: 'provision-azure-cli.sh'
  config.vm.provision :shell, path: 'provision-govc.sh'
  config.vm.provision :shell, path: 'provision-vmware-powercli.sh'
  config.vm.provision :shell, path: 'provision-vagrant.sh', args: [VAGRANT_USERNAME, VAGRANT_PASSWORD]
end
