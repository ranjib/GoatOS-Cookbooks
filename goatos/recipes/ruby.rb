%w{
  git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev
  libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev
  libcurl4-openssl-dev python-software-properties git
}.each do |pkg|
  package pkg
end

directory '/opt/rubies' do
  owner node['goatos']['user']
  group node['goatos']['user']
  mode 0755
end

git '/opt/rubies/.ruby_build' do
  action :checkout
  user node['goatos']['user']
  group node['goatos']['user']
  repository 'https://github.com/sstephenson/ruby-build.git'
end

bash 'install_ruby' do
  cwd '/opt/rubies/.ruby_build'
  code './bin/ruby-build 2.1.4 ../ruby-2.1.4'
  user node['goatos']['user']
  group node['goatos']['user']
  creates '/opt/rubies/ruby-2.1.4/bin/ruby'
end

execute 'install bundler' do
  command 'gem install bundler --no-ri --no-rdoc'
  user node['goatos']['user']
  group node['goatos']['user']
  environment(
    'PATH' => '/opt/rubies/ruby-2.1.4/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    'GEM_PATH' => '/opt/rubies/ruby-2.1.4/lib/ruby/gems/2.1.0',
    'GEM_HOME' => '/opt/rubies/ruby-2.1.4/lib/ruby/gems/2.1.0'
  )
  creates '/opt/rubies/ruby-2.1.4/bin/bundler'
end
