require 'rspec'
require 'chef/lxc'
require 'chef'
require 'chef/client'
require 'chef_zero/server'
require 'chef/knife/cookbook_upload'
require 'tempfile'
require 'fileutils'
require 'blender'
require 'blender/chef'

module SpecHelper
  extend self
  extend Chef::LXCHelper

  def server
    @server ||= ChefZero::Server.new(host: '10.0.3.1', port: 8889)
  end

  def container
    LXC::Container.new('go_cd')
  end

  def tempfile
    @file ||= Tempfile.new('go_cd-key')
  end

  def create_container
    unless  container.defined?
      container.create('download', nil, {}, 0, %w{-a amd64 -r trusty -d ubuntu})
    end
    unless container.running?
      fake_key = server.gen_key_pair.first
      container.start
      sleep 5
      recipe_in_container(container) do
        execute 'apt-get update -y'
        package 'openssh-server'
        remote_file '/opt/chef_12.0.3-1_amd64.deb' do
          source 'http://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/13.04/x86_64/chef_12.0.3-1_amd64.deb'
        end
        dpkg_package 'chef' do
          source '/opt/chef_12.0.3-1_amd64.deb'
        end
        directory '/etc/chef'
        file '/etc/chef/client.pem' do
          content fake_key
        end
        file '/etc/chef/client.rb' do
          content "chef_server_url 'http://10.0.3.1:8889'\n"
        end
        execute 'echo ubuntu:ubuntu | chpasswd'
      end
    end
  end

  def upload_cookbooks
    tempdir = Dir.mktmpdir
    repo_dir = File.expand_path('../..', __FILE__)
    FileUtils.mkdir(File.join(tempdir, 'go_cd'))
    %w{attributes recipes libraries templates metadata.rb README.md}.each do |path|
      FileUtils.cp_r(File.join(repo_dir, path), File.join(tempdir, 'go_cd'))
    end
    Chef::Knife::CookbookUpload.load_deps
    plugin = Chef::Knife::CookbookUpload.new
    plugin.config[:all] = true
    plugin.config[:cookbook_path] = [tempdir]
    plugin.run
    FileUtils.rm_rf(tempdir)
  end

  def setup
    fake_key = server.gen_key_pair.first
    server.start_background unless server.running?
    Chef::Config[:chef_server_url] = 'http://10.0.3.1:8889'
    Chef::Config[:node_name] = 'test'
    Chef::Config[:client_key] = tempfile.path
    tempfile.write(fake_key)
    tempfile.close
    upload_cookbooks
    create_container
  end

  def teardown
    container.stop if container.running?
    container.destroy if container.defined?
    tempfile.unlink
  end

  def run_chef(run_list)
    Blender.blend('chef-run', no_doc: true) do |sched|
      sched.members([container.ip_addresses.first])
      sched.config(:ssh, stdout: $stdout, user: 'ubuntu', password: 'ubuntu')
      sched.ssh_task "sudo /opt/chef/bin/chef-client --no-fork -r '#{run_list}'"
    end
  end
end
describe 'gocd_server' do
  before do
    SpecHelper.setup
  end
  it 'converge successfully' do
    SpecHelper.run_chef("recipe[go_cd::server]")
    SpecHelper.run_chef "recipe[go_cd::server],recipe[go_cd::agent]"
  end
  after do
    SpecHelper.teardown
  end
end
