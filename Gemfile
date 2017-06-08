source 'https://rubygems.org'

# Specify your gem's dependencies in redstruct.gemspec
gemspec

group :rake do
  gem 'yard' # documentation
end

group :debug do
  gem 'byebug' # debugger
  gem 'pry' # better console
  gem 'pry-byebug' # pry integration for byebug
  gem 'pry-stack_explorer' # stack exploration
end

group :test do
  gem 'flexmock', require: false
  gem 'hiredis', require: 'redis/connection/hiredis'
  gem 'minitest-reporters', require: false
end
