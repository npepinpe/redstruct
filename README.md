# Redstruct

[![Build Status](https://travis-ci.org/npepinpe/redstruct.svg?branch=master)](https://travis-ci.org/npepinpe/redstruct)

Provides higher level data structures in Ruby using standard Redis commands. Also provides basic object mapping for pre-existing types.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redstruct'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redstruct

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

*Note*

Avoid using transactions; the Redis documentation suggests using Lua scripts where possible, as in most cases they will be faster than transactions. Use the `Redstruct::Utils::Scriptable` module and the `defscript` macro instead.

## TODO

- [x] Implement factory
- [x] Implement counter
- [x] Implement lock (blocking/non-blocking)
- [x] Implement string
- [x] Implement hash
- [x] Implement set
- [x] Implement list
- [x] Implement script
- [x] Implement sorted set
- [ ] Design/discuss stored factory meta-data (i.e. keep track of created objects, clear said objects, etc.)
- [ ] Implement collections to leverage redis commands such as mget, mset, etc.
- [ ] Implement value transformers (read and write) to make reusing types with specially encoded objects easy


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/npepinpe/redstruct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
