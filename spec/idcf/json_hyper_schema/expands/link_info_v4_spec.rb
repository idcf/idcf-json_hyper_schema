require 'spec_helper'
require 'idcf/conf/test_const'
require 'idcf/json_hyper_schema'

describe 'idcf/json_hyper_schema/expands/link_info_v4' do
  analyst  = Idcf::JsonHyperSchema::Analyst.new
  data_dir = File.expand_path('expand/link', Idcf::Conf::TestConst::DATA_DIR)

  def search_link(links, title)
    links.each do |v|
      return v if v.title == title.to_s
    end
    nil
  end

  it 'no_title' do
    path  = File.expand_path('title.json', data_dir)
    links = analyst.load(path).links
    link  = search_link(links, '')
    expect(link.title).to eq ''
  end

  {
    description:       {
      none:  '',
      exist: 'test_description'
    },
    title:             {
      exist: 'exist'
    },
    method:            {
      none:  '',
      exist: 'test_exist',
      lower: 'get',
      upper: 'get'
    },
    href:              {
      none:            '/',
      no_param:        '/api',
      one_url_param:   '/api/%s',
      multi_url_param: '/api/%s/%s'
    },
    url_param_names:   {
      no_param:        [],
      one_url_param:   %w[hoge],
      multi_url_param: %w[hoge piyo]
    },
    query_param_names: {
      no_param:        [],
      one_url_param:   %w[hoge],
      multi_url_param: %w[hoge piyo]
    },
    properties:        {
      none: {}
    },
    required:          {
      none:  [],
      exist: %w[hoge piyo]
    }
  }.each do |name, v|
    path  = File.expand_path("#{name}.json", data_dir)
    links = analyst.load(path).links
    v.each do |title, result|
      it "no_param_#{name}_#{title}" do
        link = search_link(links, title)
        expect(link.__send__(name.to_sym)).to eq result
      end
    end
  end

  it 'params_check_key' do
    path  = File.expand_path('properties.json', data_dir)
    links = analyst.load(path).links
    link  = search_link(links, 'exist')
    expect(link.properties.keys).to eq %w[id num]
  end

  get_param = {
    url_param:
                [],
    params:
                {
                  'hoge' => 'h_param',
                  'piyo' => 'p_param'
                },
    host:       nil,
    uri_result: '/api?hoge=h_param&piyo=p_param',
    url_result: '/api',
    query_params_result:
                {
                  'hoge' => 'h_param',
                  'piyo' => 'p_param'
                },
    make_params_result:
                {}
  }

  list = {
    none:          {
      url_param:  [],
      params:     {},
      host:       nil,
      uri_result: '/api?',
      url_result: '/api',
      query_params_result:
                  {},
      make_params_result:
                  {}
    },
    url:           {
      url_param:  %w[aaa bbb],
      params:     {},
      host:       nil,
      uri_result: '/api/aaa/bbb?',
      url_result: '/api/aaa/bbb',
      query_params_result:
                  {},
      make_params_result:
                  {}
    },
    get_href_only: get_param,
    post:          {
      url_param:  [],
      params:     {
        'hoge' => 'h_param',
        'piyo' => 'p_param'
      },
      host:       nil,
      uri_result: '/api?',
      url_result: '/api',
      query_params_result:
                  {},
      make_params_result:
                  {
                    'hoge' => 'h_param'
                  }
    },
    mix:           {
      url_param:
                  ['aaa'],
      params:
                  {
                    'hoge' => 'h_param',
                    'piyo' => 'p_param'
                  },
      host:       nil,
      uri_result: '/api/aaa?hoge=h_param',
      url_result: '/api/aaa',
      query_params_result:
                  {
                    'hoge' => 'h_param'
                  },
      make_params_result:
                  {
                    'piyo' => 'p_param'
                  }
    }
  }

  %i[get_schema_only get_mix].each do |key|
    list[key] = list[:get_href_only].deep_dup
  end

  path  = File.expand_path('make_uri.json', data_dir)
  links = analyst.load(path).links
  list.each do |k, v|
    [nil, 'http://'].each do |host|
      it "make_uri(#{k})" do
        result = host ? URI.join(host, v[:uri_result]).to_s : v[:uri_result]
        link   = search_link(links, k)
        expect(link.make_uri(v[:url_param], v[:params], host)).to eq result
      end

      it "make_url(#{k})" do
        result = host ? URI.join(host, v[:url_result]).to_s : v[:url_result]
        link   = search_link(links, k)
        expect(link.__send__(:make_url, v[:url_param], host)).to eq result
      end
    end

    it "make_query_params(#{k})" do
      link = search_link(links, k)
      expect(link.__send__(:make_query_params, v[:params])).to eq v[:query_params_result]
    end

    it "make_params(#{k})" do
      link = search_link(links, k)
      expect(link.make_params(v[:params])).to eq v[:make_params_result]
    end
  end

  [
    [],
    %w[aaa]
  ].each do |v|
    it "make_query_params(#{v})" do
      link   = search_link(links, :none)
      result = {}
      expect(link.__send__(:make_query_params, v)).to eq result
    end
  end

  {
    none:   {
      param:  '',
      result: ''
    },
    normal: {
      param:  '{hoge}',
      result: 'hoge'
    },
    prmd:   {
      param:  ':hoge',
      result: 'hoge'
    },
    extra:  {
      param:  '{hoge}:piyo',
      result: 'hoge'
    },
    extra2: {
      param:  '{hoge}#piyo',
      result: 'hoge'
    },
    extra3: {
      param:  ':{hoge}',
      result: '{hoge}'
    }
  }.each do |k, v|
    it "url_param_str(#{k})" do
      link = search_link(links, :none)
      expect(link.__send__(:url_param_str, v[:param])).to eq v[:result]
    end
  end

  path       = File.expand_path('base_href.json', data_dir)
  href_links = analyst.load(path).links
  {
    none:     {
      href:      '/',
      base_href: ''
    },
    full:     {
      href:      'http://example.com/api/full',
      base_href: 'http://example.com'
    },
    add:      {
      href:      'http://example.com/api/add/hoge',
      base_href: 'http://example.com/api/add'
    },
    override: {
      href:      'http://example.com/override/api',
      base_href: 'http://example.com/override'
    }
  }.each do |k, v|
    %i[href base_href].each do |method|
      it "#{method}(#{k})" do
        link = search_link(href_links, k)
        expect(link.__send__(method)).to eq v[method]
      end
    end
  end
end
