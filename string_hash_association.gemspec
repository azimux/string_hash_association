$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "string_hash_association/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "string_hash_association"
  s.version     = StringHashAssociation::VERSION
  s.authors     = ['azimux']
  s.email       = ['azimux@gmail.com']
  s.homepage    = 'http://github.com/azimux/~'
  s.summary     = 'Engine for persisting a hash via active record'
  s.description = 'Engine for persisting a hash via active record'

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT_LICENSE.txt"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.12"

  s.add_development_dependency "sqlite3"
end
