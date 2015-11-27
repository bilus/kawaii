# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kawaii/version'

Gem::Specification.new do |spec|
  spec.name      = 'kawaii'
  spec.version   = Kawaii::VERSION
  spec.authors   = ['Marcin Bilski']
  spec.email     = ['gyamtso@gmail.com']

  spec.summary   = 'TODO: Write a short summary, because Rubygems requires one.'
  spec.homepage  = "TODO: Put your gem's website or public repo URL here."
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
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'yard'
end
