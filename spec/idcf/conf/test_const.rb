module Idcf
  module Conf
    class TestConst
      dir_path        = File.dirname(__FILE__)
      BASE_PATH       = File.expand_path('..', dir_path).freeze
      DATA_DIR        = File.expand_path('data', BASE_PATH)
    end
  end
end
