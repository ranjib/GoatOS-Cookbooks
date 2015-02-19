# Cookbook Name:: go-server
# Recipe:: default
include_recipe 'go_cd::default'

remote_file "#{Chef::Config[:file_cache_path]}/go-server.deb" do
  source  node['go_cd']['server_download_url']
end

dpkg_package 'go-server' do
  source "#{Chef::Config[:file_cache_path]}/go-server.deb"
end

service 'go-server' do
  action [ :enable, :start ]
  supports(
    status: true,
    start: true,
    stop: true,
    restart: true
  )
end

