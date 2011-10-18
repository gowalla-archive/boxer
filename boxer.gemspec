# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "boxer/version"

Gem::Specification.new do |s|
  s.name        = 'boxer'
  s.version     = Boxer::VERSION
  s.authors     = ['Brad Fults']
  s.email       = ['bfults@gmail.com']
  s.homepage    = 'http://github.com/h3h/boxer'
  s.license     = 'MIT'
  s.summary     = %q{Easy custom-defined templates for JSON generation of objects in Ruby.}
  s.description = %q{A composable templating system for generating JSON via Ruby hashes, withdifferent possible views on each object and runtime data passing.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', '>= 1.0.10'
  s.add_development_dependency 'rspec', '>= 2.0.0'
  s.add_runtime_dependency 'activesupport', '>= 3.0.0'
end
