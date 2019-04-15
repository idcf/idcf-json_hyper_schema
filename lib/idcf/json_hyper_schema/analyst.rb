require 'json_schema'
require 'idcf/json_hyper_schema/validation'
module Idcf
  module JsonHyperSchema
    # json-hyper-schema analyst
    class Analyst
      attr_reader :process_version, :schema, :load_schema

      def json_schema_init
        configuration = JsonSchema.configuration
        Idcf::JsonHyperSchema::Validation.validations.each do |key, val|
          configuration.register_format(key, val)
        end
        self
      end

      # json file laod
      #
      # @param path [String]
      # @param options [Hash]
      # @return [Hash]
      # @raise
      def load(path, options = {})
        @schema ||= {}
        unless @schema[path].nil?
          @load_schema = @schema[path]
          return self
        end
        j             = JSON.parse(File.read(path))
        @load_schema  = expand(j, options).schema
        @schema[path] = @load_schema
        self
      end

      # json file laod
      #
      # @param schema [Hash]
      # @param options [Hash]
      # @return [Expand::Base]
      # @raise
      def expand(schema, options = {})
        return schema unless schema.class == Hash
        @process_version = schema_version(schema)
        result           = expand_class.new(options)
        result.do!(schema)
        result
      end

      # links
      #
      # @return Expands::LinkInfoBase
      def links
        json_schema_init
        p_schema         = JsonSchema.parse!(@load_schema)
        @process_version = schema_version(p_schema)
        p_schema.expand_references!
        find_links(p_schema)
      end

      # schema links
      #
      # @param schema [Hash]
      # @param options [Hash]
      # @return Expands::LinkInfoBase
      def schema_links(schema, options = {})
        ex_schema = expand(schema, options)
        json_schema_init
        p_schema = JsonSchema.parse!(ex_schema.schema)
        t_v      = @process_version
        p_schema.expand_references!
        result           = find_links(p_schema)
        @process_version = t_v
        result
      end

      protected

      # base module
      # namespace
      #
      # @return [String]
      def base_module
        list = self.class.to_s.underscore.split('/')
        list.pop
        list.join('/')
      end

      # expand class
      #
      # @return [Class]
      def expand_class
        path = "#{base_module}/expands/#{@process_version}"
        require path
        path.classify.constantize
      end

      # find links
      #
      # @param schema [JsonSchema::Schema]
      # @return [Array]
      # @raise
      def find_links(schema)
        [].tap do |result|
          l_class = link_class
          schema.links.each do |link|
            link_obj = l_class.new(link)
            result << link_obj
          end

          schema.properties.each_value do |sub|
            result.concat(find_links(sub))
          end
        end
      end

      # link class
      #
      # @return [Idcf::JsonHyperSchema::Expands::LinkInfoBase]
      # @raise
      def link_class
        path = "#{base_module}/expands/link_info_#{@process_version}"
        require path
        path.classify.constantize
      end

      # schema version
      #
      # @param schema [Hash]
      # @return [String]
      # @raise
      def schema_version(schema)
        v_list = schema_version_list
        result = v_list.last
        check  = schema.is_a?(JsonSchema::Schema) ? schema.data : schema
        unless check['$schema'].nil? || check['$schema'].empty?
          result = schema_version_str(check['$schema'])
        end

        raise 'The undefined version.' if v_list.index(result).nil?
        result
      end

      # schema version list
      # support schema version list
      #
      # @return array
      def schema_version_list
        result = []
        Dir.glob("#{File.dirname(__FILE__)}/expands/v*.rb") do |f|
          result << File.basename(f, '.rb')
        end
        result.sort
      end

      # schema version str
      #
      # @param schema [String] $schema
      # @return [String]
      def schema_version_str(schema)
        schema =~ /draft[^\d]{1,2}(\d+)/
        mt = Regexp.last_match(1)
        return "v#{mt.to_i}" unless mt.nil?
        ''
      end
    end
  end
end
