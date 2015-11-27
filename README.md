
# Kawaii

Kawaii is a simple web framework based on Rack.

**This is work in progress. The API is subject to change.**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'kawaii-core'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kawaii-core

## Running examples

Clone the Kawaii project to run the examples. The [/examples directory](https://github.com/bilus/kawaii/tree/master/examples) contains various basic usage examples.

```
$ git clone https://github.com/bilus/kawaii.git
$ cd kawaii
```

Run the examples using rackup or directly:

```
$ cd examples
$ rackup -I ../lib modular.ru
```

Many examples can also be run directly without rackup, e.g.:

```ruby
$ cd examples
$ ruby -I ../lib hello_world.rb
```

## Getting started

Note: In addition to this Readme, there's also an online [API reference](http://bilus.github.io/kawaii/Kawaii.html).

Kawaii's basic usage is very similar how you'd use Sinatra. You can define route handlers at the file scope. Here's an example:

```ruby
require 'kawaii'

get '/' do
  'Hello, world!'
end
```

Save it to `hello.rb` and start the server like this:

```
$ rackup -r kawaii hello.rb --port 8088
```

Then navigate to `http://localhost:8088` to see the greeting.

## Using rackup

To run the app you created in the "Getting started" section above using rackup, create the following `hello.ru` file:

```ruby
require 'kawaii'
require_relative 'hello'

run Kawaii::SingletonApp
```

`SingletonApp` contains all routes defined at the file scope.

## Defining routes

There are several methods you can use to build your routes, handle passed parameters and so on.

### Supported HTTP methods

The basic way to add a route handler is to invoke a method corresponding to the given HTTP verb, e.g.:

```ruby
post '/users' do
  # Some response
end
```

Here, the `post` method corresponds to the `POST` HTTP verb.

Here's a list of supported HTTP verbs:

- get
- post
- put
- patch
- delete
- head
- options
- link
- unlink
- trace

### Wildcard matching

Patterns in route definitions may contain wildcard characters `*` and `?`.

For example `get '/users/?'` matches both `/users/` and `/users` while `get '/users/*'` will match any path starting with '/users/' e.g. '/users/foo/bar'.

### Parameters

Route patterns may contain named parameters, prefixed with a colon. Parameters are accessible through the `params` hash in handler:

```ruby
get '/users/:id' do
  params[:id]
end
```

(When requested with `/users/123`, the above route handler will render `"123"`.)

### Regular expressions

Route patterns may contain regular expressions. Example:

```ruby
get %r{/users/.*} do
  'Hello, world'
end
```

### Nested routes

Routes may be nested using the `context` method. Example:

```ruby
context '/api' do
  get '/users' do
    'Hello'
  end
end
```

Will above handler will be accessible through `/api/users`.

### Custom matchers

If string patterns and regular expression are not flexible enough, you can create a custom matcher.

A matcher instance responds to `match` method and returns either a `Match` instance or nil if there's no match. See documentation for {Kawaii::Matcher#match} for more details.

### Request object

Handlers can access the `Rack::Request` instance corresponding to the current request:

```ruby
get '/' do
  request.host
end
```

### View templates

View templates must currently be stored in `views/` directory of the project using Kawaii. They can be rendered using the `render` method:

```ruby
get '/' do
  render('index.html.erb')
end
```

You can set instance variables and use them in the templates.

```ruby
get '/' do
  @title = 'Hello, world'
  render('index.html.erb')
end
```

Let's say `views/index.html.erb` looks like this:

```html
<h1><%= @title %></h1>
```

In that case, when you visit the page, you'll see **Hello, world**.

Supported templating engines include: ERB, Haml, Liquid, Builder, Kramdown and others. Note that you may need to include the specific gem implementing the given templating engine as inferred from the file name of the template.

## Modular apps

For building more complex applications, you can split them into separate classes, each implementing a subset of functionality (e.g. website and an API).

To create an application, inherit from `Kawaii::Base` and define your routes inside the class.

Let's create `website.rb`:

```ruby
require 'kawaii'

class Website < Kawaii::Base
  get '/' do
    'Hello, world'
  end
end
```

Now here's how `api.rb` may look like:

```ruby
require 'kawaii'

class API < Kawaii::Base
  get '/info' do
    'This is some information'
  end
end
```

Let's use the apps in a `config.ru`:

```ruby
require 'kawaii'
require_relative 'website'
require_relative 'api'

map '/' do
  run Website
end

map '/api' do
  run API
end
```

## Model-view-controller apps

Kawaii supports routing to controllers by either specifying the specific controller + action for a given route or by creating automatic Restful resources (via `route`).

Let's suppose we have a controller in `hello_world.rb` has typical CRUD methods that mimick Rails controllers:

```ruby
class HelloWorld < Kawaii::Controller
  def index
    'Hello, world'
  end
end
```

An in `users.rb`:

```ruby
class Users < Kawaii::Controller
  def index
    'GET /users'
  end

  def show
    "GET /users/#{params[:id]}"
  end

  def create
    'POST /users'
  end

  def update
    "PATCH /users/#{params[:id]}"
  end

  def destroy
    "DELETE /users/#{params[:id]}"
  end
end
```

Here's how we can define routes (in `app.rb`):

```ruby
  require 'kawaii'
  require_relative 'hello_world'
  require_relative 'users'

  get '/', 'hello_world#index' # Explicitly route to `HelloWorld#index` to show the welcome page

  route '/users', 'users'
```

You can run the app directly using `ruby` or create `config.ru`:

```ruby
require_relative 'app.rb'

run Kawaii::SingletonApp
```

Of course, you can 

## Testing

I recommend using `Rack::Test` for testing (see [here](https://github.com/brynary/rack-test)). Look at specs in `spec/` to see how you can use it.

To make a long story short, a class deriving from `Kawaii::Base` containing your routes is `app`. Let's suppose, your app class is `MyApp`, here's how you could test it:

```ruby
describe MyApp
  let(:app) { MyApp }
  it 'renders home page' do
    get '/'
    expect(last_response).to be_ok
  end
end
```

## Resources

1. [API reference](http://bilus.github.io/kawaii/Kawaii.html).
2. See [examples](https://github.com/bilus/kawaii/tree/master/examples) of basic usage of Kawaii.
3. Small [example project](https://github.com/bilus/kawaii-sample) using the gem.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bilus/kawaii.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


## TODO

X Hello world app.
X Specs for the app.
X GET routes inside a class deriving from Base.
X Support for running apps without config.ru (ruby -I ./lib examples/hello_world.rb
X Top-level routes.
X Example for top-level routes.
X Nested routes.
X Modular apps (multiple modules via config.ru).
X Matchers.
X Wildcard regex routes, e.g. '/foo/bar/?'.
X Parameter-based routes. Unsupported in 'context'.
X Request object.
X Merge Rack Request params.
X String responses.
X Other HTTP verbs.
X Refactor & create individual files.
X Views (via `render` method in handlers) using Tilt.
X Rack route test helpers work.
X API reference.
X Check: References to methods defined in contexts and at class scope.
X Controllers - 'hello_world#index'
X 'route' to controllers (via class name or symbol references).
X Controllers - render.
X Push gem.
X Readme - description and tutorial.
- Rubocop-compliant.
- Update and push.

- Example project using the gem and controllers (with views).

- Rack/custom global middleware.
- Route-specific middleware.
- Custom error handling (intercept exceptions, 404 what else?).
- Code review

## Known issues

** There are many missing features and glitches are inevitable. The library hasn't been used in production yet. Please report them to `gyamtso at gmail dot com`. **

### Rubocop

`lib/kawaii/routing_methods.rb:46:1: C: Extra blank line detected.`

The extra line is necessary for Yard to ignore the comment. Adjust Rubocop settings.