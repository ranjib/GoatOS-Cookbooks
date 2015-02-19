require 'chefspec'

describe 'go_cd::server' do
  cached(:chef_run) do
    ChefSpec::ServerRunner.new(file_cache_path: '/var/chef/cache').converge(described_recipe)
  end
  it 'includes the default recipe' do
    expect(chef_run).to include_recipe('go_cd::default')
  end
  it 'download go-server installer using remote file' do
    expect(chef_run).to create_remote_file('/var/chef/cache/go-server.deb').with(
      source: 'http://download.go.cd/gocd-deb/go-server-14.2.0-377.deb'
      )
  end
  it 'install dpkg package go-server' do
    expect(chef_run).to install_dpkg_package('go-server')
  end
  it 'enable go-server service' do
    expect(chef_run).to enable_service('go-server')
  end
  it 'start go-server service' do
    expect(chef_run).to start_service('go-server').with(
      supports: {
        status: true,
        start: true,
        stop: true,
        restart: true
      }
    )
    expect(chef_run).to enable_service('go-server').with(
      supports: {
        status: true,
        start: true,
        stop: true,
        restart: true
      }
    )
  end
end
