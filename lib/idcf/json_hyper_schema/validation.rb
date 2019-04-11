require 'json_schema'
module Idcf
  module JsonHyperSchema
    # json-hyper-schema validation
    class Validation
      class << self
        attr_reader :add_validation

        def reset_format
          @add_validation = {}
          self
        end

        def register_format(name, validator_proc)
          @add_validation ||= {}
          @add_validation[name] = validator_proc
          self
        end

        def validations
          @add_validation ||= {}
          custom_validations.merge(@add_validation)
        end

        protected

        def custom_validations
          {
            'ipv4_cidr' => lambda do |data|
              ip_check(data, JsonSchema::Validator::IPV4_PATTERN)
            end,
            'ipv6_cidr' => lambda do |data|
              ip_check(data, JsonSchema::Validator::IPV6_PATTERN)
            end,
            'integer' => lambda do |data|
              data =~ /^[0-9]+$/
            end
          }
        end

        def ip_check(data, pattern)
          list = data.split('/')
          return false unless list.size == 2
          return false unless list[0] =~ pattern
          list[1] =~ /^[0-9]*$/
        end
      end
    end
  end
end
