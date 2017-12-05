require 'open-uri'
require_relative '../analyst'
module Idcf
  module JsonHyperSchema
    module Expands
      # json schema expand
      # json schema v4
      class Base
        FULL_HREF_REGEXP = Regexp.new('\A[a-zA-Z]*:?//').freeze
        attr_reader :origin,
                    :definition_ids,
                    :schema,
                    :options

        # initialize
        #
        # @param global_access [Boolean] Is an external reference performed?
        def initialize(global_access: true)
          @definition_ids = {}
          @options        =
            {
              global_access: global_access
            }
        end

        # do
        #
        # @param schema [Hash]
        # @return [Hash]
        # @raise
        def do!(schema)
          raise 'schema is not hash' unless schema.class == Hash
          target          = schema.deep_dup
          @origin         = schema.deep_dup
          @definition_ids = delete_id(make_ids(target))
          @schema         = exp(target)
          @schema
        end

        # ref find
        #
        # @param path [String]
        # @return Mixed
        def find(path)
          if path =~ FULL_HREF_REGEXP
            return path unless @options[:global_access]
            global_find(path)
          else
            local_search(path)
          end
        end

        protected

        def make_ids(schema)
          {}.tap do |result|
            next if schema['definitions'].nil?
            schema['definitions'].each do |_k, v|
              result[v['id']] = v.deep_dup unless v['id'].nil?
              result.merge!(search_child_ids(v))
            end
          end
        end

        def search_child_ids(child)
          {}.tap do |result|
            next unless child.class == Hash
            child.each do |_k, v|
              next unless v.class == Hash
              result[v['id']] = v.deep_dup unless v['id'].nil?
              result.merge!(search_child_ids(v))
            end
          end
        end

        def delete_id(data)
          return data unless data.class == Hash
          data.delete('id') if data['id'].class != Hash

          data.each do |k, v|
            data[k] = delete_id(v)
          end
          data
        end

        def exp(schema)
          case schema
          when Hash
            schema = exp_hash(schema)
          when Array
            schema = exp_array(schema)
          end

          schema
        end

        def exp_hash(schema)
          schema.keys.each do |k|
            exp = expansion(k, schema[k])
            if k == '$ref' && exp.class == Hash
              schema.delete(k)
              schema.merge!(exp)
            else
              schema[k] = exp
            end
          end
          schema
        end

        def exp_array(schema)
          schema.each_with_index do |v, k|
            schema[k] = expansion(k, v)
          end
          schema
        end

        def expansion(key, piece)
          case piece
          when String
            expansion_string(key, piece)
          when Hash, Array
            exp(piece)
          else
            piece
          end
        end

        def expansion_string(key, piece)
          return piece unless key == '$ref'
          d = find(piece)
          return piece if d.nil?
          return exp(d) if d.class == Hash || d.class == Array

          key = piece
          key = Regexp.last_match(1) if piece =~ /#(.*)/
          {
            key => d
          }
        end

        def global_find(path)
          return nil unless path =~ /#.+/
          res           = open(path)
          code, message = res.status
          raise "error: #{message}" unless code == '200'

          j      = JSON.parse(res.read)
          expand = Idcf::JsonHyperSchema::Analyst.new.expand(j)
          expand.find(Regexp.last_match(0))
        end

        # local data search
        # definitions_id or local_path
        #
        # @param path [String] ex) #definitions/name
        # @return Mixed
        def local_search(path)
          ids = @definition_ids[path]
          return ids unless ids.nil?
          paths = local_search_path_list(path)
          return nil if paths.empty?
          data = search_data(@origin, paths)
          data.nil? ? nil : delete_id(data.deep_dup)
        end

        def local_search_path_list(path)
          path[1, path.size - 1].split('/').select do |v|
            v.strip != ''
          end
        end

        def search_data(data, paths)
          result = data.deep_dup
          paths.each do |k|
            next if k.blank?
            key    = result.class == Hash ? k : k.to_i
            result = result[key]
            break if result.nil?
          end
          result
        end
      end
    end
  end
end
