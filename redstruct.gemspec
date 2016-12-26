lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redstruct/version'

Gem::Specification.new do |spec|
  spec.name          = 'redstruct'
  spec.version       = Redstruct::VERSION
  spec.authors       = ['Nicolas Pepin-Perreault']
  spec.email         = ['nicolas.pepin-perreault@offerista.com']

  spec.summary       = 'Higher level data structures for Redis.'
  spec.description   = 'Provides higher level data structures in Ruby using standard Redis commands. Also provides basic object mapping for pre-existing types.'
  spec.homepage      = 'https://npepinpe.github.com/redstruct/'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'Rakefile', 'README.md']
  spec.test_files    = Dir['test/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'redis', '>= 3.3.1', '< 4'
  spec.add_dependency 'connection_pool', '~> 2.2'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.1'
end
