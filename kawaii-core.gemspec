# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kawaii/version'

Gem::Specification.new do |spec|
  spec.name      = 'kawaii-core'
  spec.version   = Kawaii::VERSION
  spec.authors   = ['Marcin Bilski']
  spec.email     = ['gyamtso@gmail.com']

  spec.summary       = 'Kawaii is a simple web framework based on Rack'
  spec.description   = 'Kawaii is a basic but extensible web framework based on Rack'
  
  spec.homepage  = "https://github.com/bilus/kawaii"
  spec.license   = 'MIT'

  spec.files     = `git ls-files -z`.split("\x0").reject { |f|
    f.match(%r{^(test|spec|features)/})
  }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rack', '~> 1.6'
  spec.add_dependency 'tilt', '~> 2.0'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'guard-rspec', '~>4.6'
  spec.add_development_dependency 'rack-test', '~>0.6'
  spec.add_development_dependency 'yard', '~> 0.8'
end
