# coding: utf-8
lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'stampr/version'

Gem::Specification.new do |spec|
  spec.name          = "stampr"
  spec.version       = Stampr::VERSION
  spec.authors       = ["Bil Bas"]
  spec.email         = ["bil.bas.dev@gmail.com"]
  spec.summary       = %q{Wrapper for the stampr API (https://stam.pr)}
  spec.description   =<<EOT
#{spec.summary}

Sending postal mail has just moved to the cloud!
No more buying stamps or licking envelopes. Real paper mailings sent as easily as your last email.
EOT

  spec.homepage      = "https://github.com/stampr/stampr-api-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split $/
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 1.9.2" # 1.8.7 is end-of-life.

  spec.add_dependency "rest-client", "~> 1.6.7"

  spec.add_development_dependency "webmock", "~> 1.11.0"
  spec.add_development_dependency "rspec", "~> 2.13.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "redcarpet", "~> 2.3.0"
  spec.add_development_dependency "rake"
end
