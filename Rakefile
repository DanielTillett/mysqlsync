require 'bundler/gem_tasks'
require 'rake'
require 'rake/testtask'
require 'mysql2'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test