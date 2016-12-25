require 'bundler/gem_tasks'
require 'rake/testtask'

Bundler.require(:default, :development)

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

YARD::Rake::YardocTask.new do |t|
  require 'yard/defscript_handler'
  t.files   = ['lib/redstruct/*.rb']
  t.options = ['--output-dir=./docs', '--no-private']
  t.stats_options = ['--list-undoc']
end
