# -*- coding: UTF-8 -*-

require 'json'
require 'haml'
require 'haml/magic_translations'

module Haml::MagicTranslations::XGetText # :nodoc:
  # XGetText parser for Haml files
  #
  # === Example
  #
  #   GetText::Tools::XGetText.add_parser(Haml::MagicTranslations::XGetText::HamlParser)
  #   GetText.update_pofiles(text_domain, files, app_version, options)
  #
  module HamlParser
    module_function

    def target?(file) # :nodoc:
      File.extname(file) == '.haml'
    end

    def parse(file) # :nodoc:
      XGetTextParser.new(file).parse
    end

    class XGetTextParser # :nodoc:all
      attr_reader :file
      attr_reader :content
      def initialize(file)
        if file.respond_to? :read
          @file = '(haml)'
          @content = file.read
        else
          @file = file
          @content = File.open(file).read
        end
      end

      def parse
        # Engine#initialize parses and compiles
        HamlEngineCompiler.filename = @file
        Haml::Engine.new(
            content, :filename => @file,
                     :parser_class => HamlEngineParser,
                     :compiler_class => HamlEngineCompiler)
        targets = HamlEngineCompiler.targets
        HamlEngineCompiler.reset_targets
        targets
      end
    end

    class HamlEngineParser < Haml::Parser
      def tag(line)
        tag_name, attributes, attributes_hashes, object_ref, nuke_outer_whitespace,
          nuke_inner_whitespace, action, value, last_line = parse_tag(line)
        if action && (action == '=' || (action == '!' && value[0] == ?=) ||
                                       (action == '&' && value[0] == ?=))
          parsed_tag = true
        else
          parsed_tag = false
        end
        node = super(line)
        node[:value][:parsed_tag] = parsed_tag
        node
      end
    end

    class HamlEngineCompiler < Haml::Compiler
      class << self
         attr_accessor :filename

         def add_target(text, lineno)
           @targets = {} if @targets.nil?
           unless text.empty?
             @targets[text] = [] unless @targets[text]
             @targets[text].push("#{filename}:#{lineno}")
           end
         end

         def reset_targets
           @targets = {}
         end

         def targets
           (@targets || {}).keys.sort.collect do |k|
             [k] + @targets[k]
           end
         end
      end

      def compile(node)
        super(node)
      end

      def compile_plain
        HamlEngineCompiler.add_target(@node.value[:text], @node.line)
      end

      def compile_doctype
        # do nothing
      end

      def compile_script
        yield if block_given?
      end

      def compile_silent_script
        yield if block_given?
      end

      def compile_tag
        if @node.value[:parsed_tag]
          # Search for explicitely translated strings
          @node.value[:value].gsub(/_\('(([^']|\\')+)'\)/) do |m|
            parsed_string = "#{$1}"
            HamlEngineCompiler.add_target(parsed_string, @node.line)
          end
        else
          value = @node.value[:value]
          if value
            # strip quotes if needed
            value = value[1..-2] if @node.value[:parse]
            value, args = Haml::MagicTranslations.prepare_i18n_interpolation(value)
            HamlEngineCompiler.add_target(value, @node.line)
          end
        end
        # handle explicit translations in attributes
        @node.value[:attributes_hashes].each do |hash_string|
          hash_string.gsub(/_\('(([^']|\\')+)'\)/) do |m|
            HamlEngineCompiler.add_target($1, @node.line)
          end
        end
        yield if @node.value[:value].nil? && block_given?
      end

      def compile_filter
        case @node.value[:name]
        when 'markdown', 'maruku'
          HamlEngineCompiler.add_target(@node.value[:text].rstrip, @node.line)
        when 'javascript'
          lineno = 0
          @node.value[:text].split(/\r\n|\r|\n/).each do |line|
            lineno += 1
            line.gsub(/_\('(([^']|\\')+)'\)/) do |m|
              parsed_string = JSON.parse("[\"#{$1}\"]")[0]
              HamlEngineCompiler.add_target(parsed_string, @node.line + lineno)
            end
          end
        end
      end
    end
  end
end
