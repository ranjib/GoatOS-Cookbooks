node.default['go_cd']['user'] = node['goatos']['user']
node.default['go_cd']['group'] = node['goatos']['user']

include_recipe 'go_cd::server'
include_recipe 'container::install'

container_user node['goatos']['user'] do
  user node['goatos']['user']
  user_password '$1$sm3eV7iC$7IrxaH5HsiD48uTU7LPn2.'
  home_dir node['goatos']['directory']
  veth_limit node['goatos']['veth_limit']
end

include_recipe 'go_cd::agent'
include_recipe 'goatos::ruby'

xml_file '/etc/go/cruise-config.xml' do
  partial('//cruise', 'chef.xml', after: '//server')
  attribute('//cruise', 'schemaVersion', '72')
  notifies :restart, 'service[go-server]'
end
