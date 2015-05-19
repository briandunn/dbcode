require 'date'
$:.unshift File.expand_path "../lib", __FILE__
require 'dbcode/version'

Gem::Specification.new do |s|
  s.name = "dbcode"
  s.version = DBCode::VERSION
  s.authors = ["Brian Dunn"]
  s.date = Date.today.to_s
  s.description = "A Database Code Pipeline for ActiveRecord"
  s.summary = "A Database Code Pipeline for ActiveRecord"
  s.email = "brian@hashrocket.com"
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = `git ls-files -- lib/*`.split "\n"
  s.homepage = "http://github.com/briandunn/dbcode"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.4.4"
  s.add_dependency %<activerecord>, '~> 4.2'
  s.add_development_dependency %<rake>, '~> 10.4'
  s.add_development_dependency %<pg>
  s.add_development_dependency %<rspec>, '~> 3.2'
end
