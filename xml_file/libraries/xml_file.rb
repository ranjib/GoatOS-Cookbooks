require 'chef/mixin/securable'
require 'chef/mixin/enforce_ownership_and_permissions'
require 'chef/scan_access_control'
require_relative 'helper'

class Chef
  class Resource
    class XmlFile < Chef::Resource

      include Chef::Mixin::Securable

      attr_reader :partials
      attr_reader :attributes
      attr_reader :texts
      identity_attr :path
      state_attrs :owner, :group, :mode

      def initialize(name, run_context = nil)
        super
        @resource_name = :xml_file
        @action = 'edit'
        @provider = Chef::Provider::XmlFile
        @partials = Hash.new{|h,k| h[k] = {}}
        @attributes = {}
        @texts = {}
        @path = name
        allowed_actions.push(:edit)
      end

      def partial(xpath, file, position = nil)
        @partials[xpath][:file] =  file
        @partials[xpath][:position] = position
      end

      def text(xpath, content)
        @texts[xpath] = content
      end

      def attribute(xpath, name, value)
        @attributes[xpath] = { name: name, value: value }
      end

      def path(arg=nil)
        set_or_return(:path, arg, :kind_of => String)
      end
    end
  end

  class Provider
    class XmlFile < Chef::Provider

      include Chef::Mixin::EnforceOwnershipAndPermissions

      provides :xml_file

      def define_resource_requirements
        access_controls.define_resource_requirements
      end

      def load_current_resource
        @current_resource ||= Chef::Resource::XmlFile.new(new_resource.name)
        current_resource.path(new_resource.path)
        if ::File.exist?(new_resource.path)
          load_resource_attributes_from_file(current_resource)
        end
        current_resource
      end

      def load_resource_attributes_from_file(resource)
        if Chef::Platform.windows?
          return
        end
        acl_scanner = ScanAccessControl.new(@new_resource, resource)
        acl_scanner.set_all!
      end

      def whyrun_supported?
        true
      end

      def manage_symlink_access?
        false
      end

      def action_edit
        file = XMLFile.new(new_resource.path)
        updated_partials = do_partials(file)
        updated_texts = do_texts(file)
        updated_attributes = do_attributes(file)
        if updated_partials || updated_texts || updated_attributes
          converge_by "updated xml_file '#{@new_resource.name}" do
            file.write(new_resource.path)
          end
        end
        do_acl_changes
        load_resource_attributes_from_file(new_resource)
      end

      def do_partials(file)
        modified = false
        new_resource.partials.each do |xpath, spec|
          partial_path = file_cache_path(spec[:file])
          unless file.partial_exist?(xpath, partial_path)
            file.add_partial(xpath, partial_path, spec[:position])
            modified = true
          end
        end
        modified
      end

      def do_attributes(file)
        modified = false
        new_resource.attributes.each do |xpath, spec|
          unless file.same_attribute?(xpath, spec[:name], spec[:value])
            file.set_attribute(xpath, spec[:name], spec[:value])
            modified = true
          end
        end
        modified
      end

      def do_texts(file)
        modified = false
        new_resource.texts.each do |xpath, content|
          unless file.same_text?(xpath, content)
            file.add_text(xpath, content)
            modified = true
          end
        end
        modified
      end

      def do_acl_changes
        if access_controls.requires_changes?
          converge_by(access_controls.describe_changes) do
            access_controls.set_all
          end
        end
      end

      def file_cache_path(name)
        cookbook.preferred_filename_on_disk_location(run_context.node, :files, name)
      end
      def cookbook
        @cookbook ||= run_context.cookbook_collection[new_resource.cookbook_name]
      end
    end
  end
end
