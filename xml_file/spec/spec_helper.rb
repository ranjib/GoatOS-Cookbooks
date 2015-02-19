require 'rspec'
require 'chef/lxc'
require 'chef'
require 'chef/client'
require 'chef_zero/server'
require 'chef/knife/cookbook_upload'
require 'tempfile'
require 'fileutils'
require_relative '../libraries/helper'
require_relative '../libraries/xml_file'

module SpecHelper
  extend self
  extend Chef::LXCHelper

  def server
    @server ||= ChefZero::Server.new(host: '10.0.3.1', port: 8889)
  end

  def container
    @ct ||= LXC::Container.new('xml-config')
  end

  def tempfile
    @file ||= Tempfile.new('xml-config-key')
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
      end
    end
  end

  def upload_cookbooks
    tempdir = Dir.mktmpdir
    repo_dir = File.expand_path('../..', __FILE__)
    FileUtils.mkdir(File.join(tempdir, 'xml_config'))
    %w{files recipes libraries metadata.rb}.each do |path|
      FileUtils.cp_r(File.join(repo_dir, path), File.join(tempdir, 'xml_config'))
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

  def run_chef
    puts container.execute(wait: true) do
      `/opt/chef/bin/chef-client -r 'recipe[xml_file::tests]' --no-fork`
    end
  end
end

RSpec.configure do |config|
  config.fail_fast = false
  config.include SpecHelper
  config.before(:suite) do
    SpecHelper.setup
  end
  config.after(:suite) do
    SpecHelper.teardown
  end
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.backtrace_exclusion_patterns = []
end
