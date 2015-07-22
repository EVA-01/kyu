# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kyu/version'

Gem::Specification.new do |spec|
  spec.name          = "kyu"
  spec.version       = Kyu::VERSION
  spec.authors       = ["James Anthony Bruno"]
  spec.email         = ["j.bruno.che@gmail.com"]

  spec.summary       = %q{Queue to your Tumblr account.}
  spec.homepage      = "https://github.com/EVA-01/kyu"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_dependency "tumblr_client", "~> 0.8.5"
  spec.add_dependency "thor", "~> 0.19.1"
  spec.add_dependency "configliere", "~> 0.4.22"
end
