cookbook_file '/opt/cruise.xml' do
  action :create_if_missing
end

xml_file '/opt/cruise.xml' do
  partial('/pipelines',  'chef-lxc.xml')
  attribute('//pipeline[@name="Chef"]', 'alt', 'OpenSource-Chef')
  text('//pipeline[@name="ChefLXC"]/environmentvariables', 'doit')
  owner 'ubuntu'
  group 'ubuntu'
  mode 0755
end
