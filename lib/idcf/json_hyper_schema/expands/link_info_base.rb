module Idcf
  module JsonHyperSchema
    module Expands
      # Link Info Base
      # json schema v4
      class LinkInfoBase
        attr_reader :data
        FULL_HREF_REGEXP    = Regexp.new('\A[a-zA-Z]*:?//').freeze
        PARAMS_REGEXP       = Regexp.new(':(.+)|\{([^\}\?]+)\}').freeze
        BIND_PARAMS_REGEXP  = Regexp.new('\A#(/|[a-zA-Z_\-])*\Z').freeze
        QUERY_PARAMS_REGEXP = Regexp.new('\{\?(.*)\}').freeze

        def initialize(data)
          @data = data
        end

        # description
        #
        # @return String
        def description
          @data.description.nil? ? '' : @data.description
        end

        # title
        #
        # @return String
        def title
          @data.title.nil? ? '' : @data.title
        end

        # method
        #
        # @return String
        def method
          @data.method.nil? ? 'get' : @data.method.to_s.downcase
        end

        # is_method
        #
        # @return String
        def method?(val)
          method == val.to_s.downcase
        end

        # href string
        #
        # @return String
        def href
          href_str = @data.href
          return '' if href_str.nil?
          l = []
          href_str.split('/').each do |v|
            next if v.empty?
            l << v.gsub(PARAMS_REGEXP, '%s').gsub(QUERY_PARAMS_REGEXP, '')
          end
          href_head = href_str =~ FULL_HREF_REGEXP ? "#{l.shift}/" : base_href
          "#{href_head}/#{l.join('/')}"
        end

        # url params
        # ex) /hoge/{id}/{sec}{?name} : ["id", "sec"]
        #
        # @return Array
        def url_param_names
          [].tap do |result|
            href = @data.href
            next if href.nil?
            href.split('/').each do |v|
              str = url_param_str(v)
              result << str unless str.empty?
            end
          end
        end

        # http query params
        # ex) /hoge/{id}/{sec}{?name} : ["name"]
        #
        # @return Array
        def query_param_names
          result = [].tap do |list|
            href = @data.href
            next if href.nil?
            params = href =~ QUERY_PARAMS_REGEXP
            next if params.nil?
            list.concat(Regexp.last_match(1).split(','))
          end
          result.concat(properties.keys) if method?('get')
          result.uniq
        end

        # properties
        #
        # @return Hash
        def properties
          d = @data.schema
          return {} if d.nil? || d.properties.nil?
          d.properties.deep_dup
        end

        # required
        #
        # @return Array
        def required
          d = @data.schema
          return [] if d.nil? || d.required.nil?
          d.required.deep_dup
        end

        # make uri
        #
        # @param url_params [Array]
        # @param params [Hash]
        # @param host [String]
        # @return String
        def make_uri(url_params, params, host = nil)
          uri          = URI(make_url(url_params, host))
          query_params = []
          [uri.query, make_query_params(params).to_param].each do |param|
            query_params << param if param.present?
          end
          uri.query = query_params.join('&')
          uri.to_s
        end

        # make params
        # The price of the rest except for a query parameter
        #
        # @param args
        # @return Hash
        def make_params(args)
          {}.tap do |result|
            param = args.deep_dup
            next unless param.class == Hash
            param = param.stringify_keys
            make_query_params(args).each_key do |qk|
              param.delete(qk)
            end
            properties.each_key do |pk|
              result[pk] = param[pk] if param.key?(pk)
            end
          end
        end

        protected

        def make_url(args, host = nil)
          result   = href
          r_params = []
          url_param_names.each_index do |index|
            r_params << CGI.escape(args[index])
          end
          result = result % r_params unless r_params.empty?
          result = URI.join(host, result).to_s unless host.nil?
          result
        end

        def make_query_params(param)
          {}.tap do |result|
            next unless param.class == Hash
            query_param_names.each do |k|
              result[k] = param[k] if param.key?(k)
            end
          end
        end

        def url_param_str(piece)
          return '' unless piece =~ PARAMS_REGEXP
          (1..2).each do |num|
            next if Regexp.last_match(num).nil?
            p_name = url_param_name(Regexp.last_match(num))
            return p_name unless p_name.nil?
          end
          ''
        end

        def base_href
          list = []
          parent_base_urls(@data.parent).each do |base|
            list << base.gsub(%r{\A/+}, '').gsub(%r{\Z/+}, '')
            break if base =~ FULL_HREF_REGEXP
          end
          list.reverse.join('/')
        end

        def parent_base_urls(schema)
          [].tap do |result|
            next if schema.nil?
            result << schema.data['base'] unless schema.data['base'].nil?
            result.concat(parent_base_urls(schema.parent))
          end
        end

        def url_param_name(name)
          return nil if name[0] == '?'
          return name unless name =~ BIND_PARAMS_REGEXP
          name.split('/').pop
        end
      end
    end
  end
end
