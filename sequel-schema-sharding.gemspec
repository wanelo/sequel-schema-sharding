# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sequel/schema-sharding/version'

Gem::Specification.new do |spec|
  spec.name          = 'sequel-schema-sharding'
  spec.version       = Sequel::SchemaSharding::VERSION
  spec.authors       = ['Paul Henry', 'James Hart', 'Eric Saxby']
  spec.email         = %w(dev@wanelo.com)
  spec.description   = %q{}
  spec.summary       = %q{Create horizontally sharded Sequel models with Postgres}
  spec.homepage      = 'https://github.com/wanelo/sequel-schema-sharding'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_dependency 'sequel'
  spec.add_dependency 'pg'
  spec.add_dependency 'sequel-replica-failover'
  spec.add_dependency 'ruby-usdt', '>= 0.2.2'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
