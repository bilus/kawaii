
# Kawaii

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/kawaii`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kawaii'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kawaii

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kawaii.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


## TODO

+ Hello world app.
+ Specs for the app.
+ GET routes inside a class deriving from Base.
+ Support for running apps without config.ru (ruby -I ./lib examples/hello_world.rb
+ Top-level routes.
+ Example for top-level routes.
+ Nested routes.
- Modular apps (multiple modules via config.ru).
- Other HTTP verbs.
- Refactor.


- String and hash responses.
- Parameter-based routes.
- Wildcard regex routes, e.g. '/foo/bar/?'.
- References to blocks (procs) in route definitions.
- Action controllers (via class name or symbol references). ASK route '/hello/', HelloWorldController
- Gem, Readme, API reference.
- Example project.
- Rubocop-compliant.
- Rack/custom global middleware.
- Route-specific middleware.
- Rack route test helpers.
- Custom error handling (intercept exceptions, 404 what else?).
