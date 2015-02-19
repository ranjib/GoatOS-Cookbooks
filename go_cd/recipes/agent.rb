include_recipe 'go_cd::default'
zip_name = node['go_cd']['agent_download_url'].split('/').last
zip_dir = zip_name.sub(/\-\d+.zip/,'')
zip_path = File.join(Chef::Config[:file_cache_path], zip_name)
bootstrapper_path = File.join(Chef::Config[:file_cache_path], zip_dir, 'agent-bootstrapper.jar')
go_server_ip = node['go_cd']['server_ip'],

%W{
  /usr/share/go-agent
  /var/lib/go-agent
  /var/run/go-agent
  /var/log/go-agent
  /var/lib/go-agent/config
}.each do |dir|
  directory dir do
    owner node['go_cd']['user']
    group node['go_cd']['group']
    mode 0755
  end
end

remote_file zip_path do
  owner node['go_cd']['user']
  group node['go_cd']['group']
  source node['go_cd']['agent_download_url']
  mode 0644
end

execute 'extract_zip' do
  command "unzip #{zip_name}"
  cwd Chef::Config[:file_cache_path]
  creates bootstrapper_path
end

remote_file '/usr/share/go-agent/agent-bootstrapper.jar' do
  source "file://#{bootstrapper_path}"
  owner node['go_cd']['user']
  group node['go_cd']['group']
end

template '/etc/default/go-agent' do
  owner node['go_cd']['user']
  group node['go_cd']['group']
  mode 0644
  source 'agent_config.sh.erb'
  variables(
    server_host: go_server_ip,
    server_port: 8153,
    work_dir: '/var/lib/go-agent',
    java_home: '/usr/lib/jvm/java-7-openjdk-amd64/jre'
  )
end

template '/etc/init.d/go-agent' do
  owner node['go_cd']['user']
  group node['go_cd']['group']
  source 'agent_init.sh.erb'
  variables(user: node['go_cd']['user'])
  mode 0751
end

template '/usr/share/go-agent/agent.sh' do
  owner node['go_cd']['user']
  group node['go_cd']['group']
  source 'agent_start.sh'
  mode 0751
end

template '/var/lib/go-agent/log4j.properties' do
  owner node['go_cd']['user']
  group node['go_cd']['group']
  source 'log4j.properties.erb'
  mode 0644
end

service 'go-agent' do
  action [ :start , :enable]
  supports status: true
end
