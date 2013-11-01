# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mysqlsync/version'

Gem::Specification.new do |s|
  s.version       = Mysqlsync::VERSION
  s.name          = 'mysqlsync'
  s.authors       = 'Nicola Strappazzon C.'
  s.email         = 'nicola51980@gmail.com'
  s.description   = 'MySQL Sync tool'
  s.summary       = 'MySQL Sync Tool'
  s.homepage      = 'https://github.com/nicola51980/mysqlsync'
  s.license       = 'MIT'
  s.files         = Dir.glob("{bin,lib}/**/*") + %w(LICENSE.txt README.md)
  s.bindir        = 'bin'
  s.executables   = 'mysqlsync'
  s.require_paths = ['lib']
  s.has_rdoc      = false
end
