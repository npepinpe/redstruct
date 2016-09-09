require 'bundler/gem_tasks'
require 'rake/testtask'

Bundler.require(:default, :development)

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test

require 'redstruct/yard/defscript_handler'
YARD::Rake::YardocTask.new do |t|
 t.files   = ['lib/**/*.rb']
 t.options = ['--output-dir=./docs']
end
