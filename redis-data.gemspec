lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis/data/version'

Gem::Specification.new do |spec|
  spec.name          = 'redis-data'
  spec.version       = Redis::Data::VERSION
  spec.authors       = ['Nicolas Pepin-Perreault']
  spec.email         = ['nicolas.pepin-perreault@offerista.com']

  spec.summary       = %q{Higher level data structures for Redis.}
  spec.description   = %q{Provides higher level data structures in Ruby using standard Redis commands. Also provides basic object mapping for pre-existing types.}
  spec.homepage      = 'https://github.com/npepinpe/redis-data'
  spec.license       = "MIT"

  spec.files         = Dir['lib/**/*', 'Rakefile', 'README.md']
  spec.test_files    = Dir['test/**/*']
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
end
