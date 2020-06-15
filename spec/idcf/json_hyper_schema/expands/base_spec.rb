require 'spec_helper'
require 'idcf/conf/test_const'
require 'idcf/json_hyper_schema'
require 'idcf/json_hyper_schema/expands/base'

describe 'idcf/json_hyper_schema/expands/base' do
  cls             = Idcf::JsonHyperSchema::Expands::Base
  data_dir        = File.expand_path('expand', Idcf::Conf::TestConst::DATA_DIR)
  EXPAND_OTHER_HASH_LIST = [
    nil,
    true,
    false,
    'str',
    1,
    [],
    ['str'],
    [1]
  ].freeze

  [
    {},
    {
      global_access: false
    }
  ].each do |v|
    it 'new' do
      expect do
        # MEMO:
        # The following warning appears in Ruby 2.7 series.
        #
        # Using the last argument as keyword parameters is deprecated; maybe ** should be added to the call
        #
        # If you want to support only Ruby 2.7 or higher, it is not necessary to distinguish between cases, but it is not so.
        if RUBY_VERSION >= '2.7'
          cls.new(**v)
        else
          cls.new(v)
        end
      end.not_to raise_error(Exception)
    end
  end

  obj = cls.new

  EXPAND_OTHER_HASH_LIST.each do |v|
    it 'do!_other_hath' do
      expect do
        obj.do!(v)
      end.to raise_error(Exception)
    end
  end

  it 'do!_unconverted' do
    path = File.expand_path('all_after.json', data_dir)
    j    = JSON.parse(File.read(path))
    expect(
      obj.do!(j)
    ).to eq j
  end

  %w(fullpath id hash_id url all).each do |name|
    it "do!_#{name}" do
      path   = File.expand_path("#{name}_before.json", data_dir)
      before = JSON.parse(File.read(path))
      path   = File.expand_path("#{name}_after.json", data_dir)
      after  = JSON.parse(File.read(path))
      expect(obj.do!(before)).to eq after
    end
  end
end
