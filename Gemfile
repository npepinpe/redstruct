source 'https://rubygems.org'

# Specify your gem's dependencies in redstruct.gemspec
gemspec

group :rake do
  gem 'yard' # documentation
end

group :development, :test do
  gem 'byebug' # debugger
  gem 'dotenv' # better environment variables handling for development/testing
  gem 'pry' # better console
  gem 'pry-byebug' # pry integration for byebug
  gem 'pry-stack_explorer' # stack exploration
end

group :test do
  gem 'flexmock', require: false
  gem 'simplecov', require: false
  gem 'codacy-coverage', require: false
end
