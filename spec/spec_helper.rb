# -*- coding: UTF-8 -*-

ENV["RAILS_ENV"] = "test"
require 'rubygems'
require 'rspec'

$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), '../lib')

require 'active_support'
require 'action_view'

require 'haml/magic_translations'
require 'haml/template'

Haml::Options.defaults[:ugly] = false
Haml::Options.defaults[:format] = :xhtml

def render(text, options = {}, &block)
  scope  = options.delete(:scope)  || Object.new
  locals = options.delete(:locals) || {}
  Haml::Engine.new(text, options).to_html(scope, locals, &block)
end
