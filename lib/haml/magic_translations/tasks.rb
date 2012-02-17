require 'rake'
require 'rake/tasklib'
require 'gettext'
require 'gettext/tools'
require 'gettext/tools/rgettext'

require 'haml/magic_translations/rgettext/haml_parser'

module Haml::MagicTranslations::Tasks
  class UpdatePoFiles < ::Rake::TaskLib
    attr_accessor :name

    # See http://rubydoc.info/gems/gettext/2.1.0/GetText#update_pofiles-instance_method
    # for details

    attr_accessor :text_domain
    attr_accessor :files
    attr_accessor :app_version
    attr_accessor :lang
    attr_accessor :po_root
    attr_accessor :msgmerge
    attr_accessor :verbose

    def initialize(name = :update_pofiles)
      @name = name

      yield self if block_given?

      define
    end

  protected

    def define
      desc "Update PO files"
      task(name) do
        [ :text_domain, :files, :app_version ].each do |opt|
          abort "`#{opt}` needs to be set." if send(opt).nil?
        end
        options = {}
        [ :lang, :po_root, :verbose ].each do |opt|
          options[opt] = send(opt) if send(opt)
        end
        GetText::RGetText.add_parser(Haml::MagicTranslations::RGetText::HamlParser)
        GetText.update_pofiles(text_domain, files, app_version, options)
      end
    end
  end
end
