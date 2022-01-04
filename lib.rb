require 'open3'
require 'base64'
require 'digest/sha1'
require 'fileutils'
require 'stringio'
require 'zlib'

def get_docker_hub_auth
  config_path = File.expand_path '~/.docker/config.json'
  return nil unless File.exists? config_path
  config = JSON.load File.read(config_path)
  return nil unless config.has_key?('auths') && config['auths'].has_key?('https://index.docker.io/v1/')
  config['auths']['https://index.docker.io/v1/']['auth']
end

def gzip_base64(data)
  o = StringIO.new()
  w = Zlib::GzipWriter.new(o)
  w.write(data)
  w.close()
  Base64.strict_encode64(o.string)
end

# add the cloud-init data as a NoCloud cloud-init iso.
# NB libvirtd libvirt-qemu:kvm MUST have read permissions to the iso file path.
# see https://cloudinit.readthedocs.io/en/latest/topics/datasources/nocloud.html
def create_cloud_init_iso(cloud_init_data_path, env, config, group, cloud_init_user_data, cloud_init_network_config)
  if !File.exists?(cloud_init_data_path) || File.mtime(cloud_init_data_path) < File.mtime(__FILE__)
    cloud_init_data_parent_path = File.dirname(cloud_init_data_path)
    FileUtils.mkdir_p(cloud_init_data_parent_path, :mode => 0750)
    FileUtils.chown(nil, group, cloud_init_data_parent_path) if group
    FileUtils.rm_f(cloud_init_data_path)
    FileUtils.mkdir_p('tmp/cidata')
    File.write('tmp/cidata/meta-data', '{}')
    File.write('tmp/cidata/user-data', "#cloud-config\n#{cloud_init_user_data.to_json}")
    File.write('tmp/cidata/network-config', cloud_init_network_config.to_json)
    env.ui.info "Creating the cloud-init cidata.iso file at #{cloud_init_data_path}..."
    raise 'Failed to execute xorriso to create the cloud-init cidata.iso file' unless system(
      'xorriso',
        '-as', 'genisoimage',
        '-output', cloud_init_data_path,
        '-volid', 'cidata',
        '-joliet',
        '-rock',
        'tmp/cidata')
    env.ui.info 'The cloud-init cidata.iso file was created as:'
    system('iso-info', '--no-header', '-i', cloud_init_data_path)
  end
end
def create_cloud_init_iso_trigger(config, group, cloud_init_user_data, cloud_init_network_config)
  cloud_init_data_path = "#{ENV['TMP'] || '/tmp'}/cidata/cidata-#{Digest::SHA1.hexdigest(__FILE__)}.iso"
  config.trigger.before :up do |trigger|
    trigger.ruby do |env, machine|
      create_cloud_init_iso(cloud_init_data_path, env, config, group, cloud_init_user_data, cloud_init_network_config)
    end
  end
  cloud_init_data_path
end
