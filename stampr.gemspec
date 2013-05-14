# coding: utf-8
lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'stampr/version'

Gem::Specification.new do |spec|
  spec.name          = "stampr"
  spec.version       = Stampr::VERSION
  spec.authors       = ["Bil Bas"]
  spec.email         = ["bil.bas.dev@gmail.com"]
  spec.description   = %q{TODO: Write a gem description}
  spec.summary       = %q{TODO: Write a gem summary}
  spec.homepage      = "https://github.com/stampr/stampr-api-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split $/
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client", "~> 1.6.7"

  spec.add_development_dependency "webmock", "~> 1.11.0" 
  spec.add_development_dependency "rspec", "~> 2.13.1"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
