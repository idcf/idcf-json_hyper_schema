require 'spec_helper'
require 'idcf/conf/test_const'
require 'idcf/json_hyper_schema'
require 'idcf/json_hyper_schema/expands/base'
require 'idcf/json_hyper_schema/expands/link_info_base'

describe 'idcf/json_hyper_schema/analyst' do
  analyst         = Idcf::JsonHyperSchema::Analyst.new
  data_dir        = Idcf::Conf::TestConst::DATA_DIR
  ANALYST_OTHER_HASH_LIST = [
    nil,
    true,
    false,
    'str',
    1,
    [],
    ['str'],
    [1]
  ].freeze
  it 'base_module' do
    expect(analyst.__send__(:base_module)).to eq 'idcf/json_hyper_schema'
  end

  it 'refute_expand_class' do
    expect do
      analyst.__send__(:expand_class)
    end.to raise_error(Exception)
  end

  it 'refute_link_class' do
    expect do
      analyst.__send__(:link_class)
    end.to raise_error(Exception)
  end

  %w(notfound empty.txt not_found_schema_version.json).each do |v|
    it 'refute_load' do
      expect do
        analyst.load(File.expand_path(v, data_dir))
      end.to raise_error(Exception)
    end
  end

  ANALYST_OTHER_HASH_LIST.each do |v|
    it 'expand_not_hash' do
      expect(analyst.expand(v)).to eq v
    end
  end

  %w(not_schema_version.json not_link.json empty_link.json).each do |v|
    it 'assert_load_no_link' do
      path = File.expand_path(v, data_dir)
      expect(analyst.load(path)).to eq analyst
    end
  end

  [
    {
      method: :expand_class,
      cls:    Idcf::JsonHyperSchema::Expands::Base
    },
    {
      method: :link_class,
      cls:    Idcf::JsonHyperSchema::Expands::LinkInfoBase
    }
  ].each do |v|
    it v[:method].to_s do
      cls    = v[:cls]
      result = analyst.__send__(v[:method]) < cls
      expect(result).to eq true
    end
  end

  it 'no_links' do
    expect(analyst.links.empty?).to eq true
  end

  %w(not_link.json empty_link.json onelink.json).each do |v|
    it 'assert_load' do
      expect(analyst.load(File.expand_path(v, data_dir))).to eq analyst
    end
  end

  it 'links' do
    expect(analyst.links.empty?).to eq false
  end

  it 'expand' do
    j = File.read(File.expand_path('onelink.json', data_dir))
    expect(analyst.expand(JSON.parse(j))).not_to eq analyst
  end

  it 'links' do
    expect(analyst.links.empty?).to eq false
  end

  %w(not_link.json empty_link.json).each do |v|
    it 'schema_no_links' do
      j = JSON.parse(File.read(File.expand_path(v, data_dir)))
      expect(analyst.schema_links(j).empty?).to eq true
    end
  end

  %w(onelink.json).each do |v|
    it 'schema_links' do
      j = JSON.parse(File.read(File.expand_path(v, data_dir)))
      expect(analyst.schema_links(j).empty?).to eq false
    end
  end

  ANALYST_OTHER_HASH_LIST.each do |v|
    it 'refute_find_links' do
      expect do
        analyst.__send__(:find_links, v)
      end.to raise_error(Exception)
    end
  end

  [
    {
      file:   'not_link.json',
      result: true
    },
    {
      file:   'empty_link.json',
      result: true
    },
    {
      file:   'onelink.json',
      result: false
    }
  ].each do |v|
    it 'find_links' do
      j      = JSON.parse(File.read(File.expand_path(v[:file], data_dir)))
      schema = JsonSchema.parse!(j)
      schema.expand_references!
      expect(analyst.__send__(:find_links, schema).empty?).to eq v[:result]
    end
  end

  [
    {
      schema: '',
      result: analyst.__send__(:schema_version_list).last
    },
    {
      schema: 'draft-04',
      result: 'v4'
    },
    {
      schema: 'draft-4',
      result: 'v4'
    },
    {
      schema: 'draft-v4',
      result: 'v4'
    },
    {
      schema: 'draft-v4.0',
      result: 'v4'
    },
    {
      schema: 'http://json-schema.org/draft-04/schema#',
      result: 'v4'
    },
    {
      schema: 'http://json-schema.org/draft-04/hyper-schema#',
      result: 'v4'
    },
    {
      schema:  'not found',
      raise_f: true
    },
    {
      schema:  'draft--v4',
      raise_f: true
    },
    {
      schema:  'draft4',
      raise_f: true
    },
    {
      schema:  'http://json-schema.org/schema#',
      raise_f: true
    },
    {
      schema:  'http://json-schema.org/hyper-schema#',
      raise_f: true
    },
    {
      schema:  'http://json-schema.org/draft-03/schema#',
      raise_f: true
    },
    {
      schema:  'http://json-schema.org/draft-03/hyper-schema#',
      raise_f: true
    },
    {
      schema:  'http://json-schema.org/draft-05/schema#',
      raise_f: true
    },
    {
      schema:  'http://json-schema.org/draft-05/hyper-schema#',
      raise_f: true
    }
  ].each do |v|
    [true, false].each do |hash_f|
      it 'schema_version' do
        j            = JSON.parse(File.read(File.expand_path('not_link.json', data_dir)))
        j['$schema'] = v[:schema]
        schema       = JsonSchema.parse!(j)
        schema.expand_references!
        target = hash_f ? j : schema
        if !v[:raise_f].nil? && v[:raise_f]
          expect do
            analyst.__send__(:schema_version, target)
          end.to raise_error(Exception)
        else
          expect(analyst.__send__(:schema_version, target)).to eq v[:result]
        end
      end
    end
  end
end
