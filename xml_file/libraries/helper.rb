require 'rexml/document'

class XMLFile
  class NonExistentElementError < StandardError; end

  attr_reader :doc, :formatter

  def initialize(path = nil)
    if File.exist?(path)
      @doc = REXML::Document.new(File.new(path))
    else
      @doc = REXML::Document.new('')
    end
    @formatter = REXML::Formatters::Pretty.new
    @formatter.compact = true
  end

  def add_partial(xpath, partial_path, position = nil)
    partial = REXML::Document.new(File.new(partial_path))
    if position
      if position[:after]
        fetch!(xpath).insert_after(position[:after], partial.root)
      elsif position[:before]
        fetch!(xpath).insert_before(position[:before], partial.root)
      end
    else
      fetch!(xpath).add(partial.root)
    end
  end

  def add_text(xpath, text)
    fetch!(xpath).text = text
  end

  def same_text?(xpath, text)
    fetch!(xpath).text == text
  end

  def set_attribute(xpath, attr, value)
    fetch!(xpath).attributes[attr] = value
  end

  def same_attribute?(xpath, attr, value)
    attribute_exist?(xpath, attr) && fetch!(xpath).attributes[attr] == value
  end

  def attribute_exist?(xpath, attr)
    fetch!(xpath) && fetch!(xpath).attributes.key?(attr)
  end

  def fetch(xpath)
    doc.elements[xpath]
  end

  def fetch!(xpath)
    el = fetch(xpath)
    if el.nil?
      raise NonExistentElementError, "XPath: #{xpath} does not exist" if el.nil?
    else
      el
    end
  end

  def write(out)
    File.open(out, 'w') do |f|
      formatter.write(doc, f)
    end
  end

  def partial_exist?(xpath, partial_path)
    buf1 = StringIO.new
    partial = REXML::Document.new(File.new(partial_path))
    formatter.write(partial, buf1)
    doc.elements[xpath].children.any? do |el|
      buf2 = StringIO.new
      formatter.write(el, buf2)
      buf2.string == buf1.string
    end
  end
end
