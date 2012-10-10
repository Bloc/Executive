# -*- encoding: utf-8 -*-
require File.expand_path('../lib/executive/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Roshan Choxi"]
  gem.email         = ["roshan.choxi@gmail.com"]
  gem.description   = %q{a Foreman wrapper with extra utilities.}
  gem.summary       = %q{executive allows you to restart Foreman processes and deploy using Heroku conventions.}
  gem.homepage      = "http://roshfu.com"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "executive"
  gem.require_paths = ["lib"]
  gem.version       = Executive::VERSION

  gem.add_runtime_dependency "colorize"
  gem.add_runtime_dependency "foreman"
  gem.add_runtime_dependency "heroku"
end
