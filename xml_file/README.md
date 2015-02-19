## xml_file - Cookbook

`xml_file` cookbook provides chef resource-provider to manage
XML files.

### Usage

`xml_file` resource allows managing only parts XML file. Users
can specify expectd content against `XPath` targets. Following
are three ways to specify content:

The 'partial' method to add a XML file fragment. Following example will
insert `part.xml` (present in `files/default` directory of the same cookbook)
as '/parent/child' XPath target's last element.
`whole.xml`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <>
  <repo type="git"></repo>
<project>
```

`part.xml`
```xml
```

```ruby
xml_file '/opt/whole.xml' do
  partial '/parent/child', 'part.xml'
  owner 'root'
  group 'root'
  mode 0644
end
```
You can specify `before` or `after` XPath values to insert the elements
at certain position with respective to their siblings.
The `attribute` method will set the value of an XML element's attribute.
Following example will set `environment` attribute of the element (found
in XPath `/parent/child`) to 'development'.

```ruby
xml_file '/opt/whole.xml' do
  attribute '/parent/child', 'environment', 'development'
  owner 'root'
  group 'root'
  mode 0644
end
```
The `text` method will set the text content of an XML element. Example:

```ruby
xml_file '/opt/whole.xml' do
  text '/parent/child', 'test-content'
  owner 'root'
  group 'root'
  mode 0644
end
```

All three methods can be combined.

`xml_file` resource only supprts :edit action currently. Its written in
REXML and should be portable across platforms.

## License
[Apache 2](http://www.apache.org/licenses/LICENSE-2.0)

## Contributing

1. Fork it ( https://github.com/goatos/xml_file/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
