# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'idcf/json_hyper_schema/version'

Gem::Specification.new do |spec|
  spec.name    = 'idcf-json_hyper_schema'
  spec.version = Idcf::JsonHyperSchema::VERSION
  spec.authors = ['IDC Frontier Inc.']
  spec.email   = []

  spec.summary     = 'IDCF Json-Hyper-Schema Expand tools'
  spec.description = 'IDCF Json-Hyper-Schema Expand tools'
  spec.homepage    = 'https://www.idcf.jp'
  spec.license     = 'MIT'

  spec.files       = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.14'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec'

  spec.add_dependency 'activerecord', '>= 5.2.4.1'
  spec.add_dependency 'activesupport', '>= 5.2.4.1'
  spec.add_dependency 'json_schema', '~> 0.17.0'
end
