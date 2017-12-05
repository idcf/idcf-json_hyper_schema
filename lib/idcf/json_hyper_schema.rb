require_relative './json_hyper_schema/version'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/class/attribute'
require 'active_support/dependencies/autoload'
require 'json_schema'

module Idcf
  # json_hyper_schema
  module JsonHyperSchema
    extend ActiveSupport::Autoload
    autoload :Analyst, 'idcf/json_hyper_schema/analyst'
  end
end
