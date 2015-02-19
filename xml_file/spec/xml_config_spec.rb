require 'spec_helper'
require 'fileutils'

describe 'XmlFile HWRP' do
  let(:formatter) do
    REXML::Formatters::Pretty.new
  end
  let(:input) do
    REXML::Document.new(File.new('spec/data/input.xml'))
  end
  let(:output) do
    REXML::Document.new(File.new('spec/data/output.xml'))
  end
  context '#partials' do
    let(:partial) do
      REXML::Document.new(File.new('spec/data/partial.xml'))
    end
    it 'should add partial' do
      file = XMLFile.new('spec/data/input.xml')
      file.add_partial('//tasks', 'spec/data/partial.xml')
      file.write('spec/data/output.xml')
      buf1 = StringIO.new
      buf2 = StringIO.new
      formatter.write(partial, buf1)
      formatter.write(output.elements['//exec[last()]'], buf2)
      expect(buf1.string).to eq(buf2.string)
      out = XMLFile.new('spec/data/output.xml')
      expect(out.partial_exist?('//tasks', 'spec/data/partial.xml')).to be(true)
    end
  end
  context '#attributes' do
    it 'should set attribute' do
      file = XMLFile.new('spec/data/input.xml')
      file.set_attribute('//tasks', 'foo', 'bar')
      file.write('spec/data/output.xml')
      expect(output.elements['//tasks'].attributes['foo']).to eq('bar')
      out = XMLFile.new('spec/data/output.xml')
      expect(out.same_attribute?('//tasks', 'foo', 'bar')).to be(true)
    end
  end
  context '#text content' do
    it 'should set text content' do
      file = XMLFile.new('spec/data/input.xml')
      file.add_text('/pipeline/environmentvariables', 'test-content')
      file.write('spec/data/output.xml')
      expect(output.elements['/pipeline/environmentvariables'].text).to eq('test-content')
      out = XMLFile.new('spec/data/output.xml')
      expect(out.same_text?('/pipeline/environmentvariables', 'test-content')).to be(true)
    end
  end
  context '#hwrp' do
    it 'should stay idempotent' do
      File.unlink('spec/data/hwrp.xml') if File.exist?('spec/data/hwrp.xml')
      FileUtils.cp('spec/data/input.xml', 'spec/data/hwrp.xml')
      events = Chef::EventDispatch::Dispatcher.new
      rc = Chef::RunContext.new(Chef::Node.new, nil, events)
      resource = Chef::Resource::XmlFile.new('spec/data/hwrp.xml', rc)
      resource.owner('ranjib')
      resource.group('ranjib')
      resource.mode('777')
      resource.attribute('//tasks', 'bar', 'baz')
      resource.run_action(:edit)
      out = REXML::Document.new(File.new('spec/data/hwrp.xml'))
      expect(out.elements['//tasks'].attributes['bar']).to eq('baz')
    end
  end
end
