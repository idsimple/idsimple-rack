# Idsimple::Rack

## Overview
Idsimple works with all [Rack](https://github.com/rack/rack)-based applications.
This includes:
- [Ruby on Rails](https://rubyonrails.org/)
- [Sinatra](http://sinatrarb.com/)
- [Hanami](https://hanamirb.org/)
- [Camping](http://www.ruby-camping.com/)
- [Coset](http://leahneukirchen.org/repos/coset/)
- [Padrino](http://padrinorb.com/)
- [Ramaze]()
- [Roda](https://github.com/jeremyevans/roda)
- [Rum](https://github.com/leahneukirchen/rum)
- [Utopia](https://github.com/socketry/utopia)
- [WABuR](https://github.com/ohler55/wabur)


All you need is the [idsimple-rack gem](https://github.com/idsimple/idsimple-rack).
`idsimple-rack` includes a [Rack app](https://github.com/rack/rack/blob/master/SPEC.rdoc#rack-applications-),
`Idsimple::Rack::AuthenticatorApp`, for authenticating users and initiating sessions
and a Rack middleware, `Idsimple::Rack::ValidatorMiddleware`, for validating access tokens and sessions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "idsimple-rack"
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install idsimple-rack
```

## Ruby on Rails
`idsimple-rack` hooks in to Rails automatically using [Rails::Railtie](https://api.rubyonrails.org/classes/Rails/Railtie.html).
All you need to do is add an initializer with your [configuration options](#configuration):

```ruby
# config/initializers/idsimple_rack.rb

Idsimple::Rack.configure do |config|
  config.app_id = ENV["IDSIMPLE_APP_ID"]
  config.api_key = ENV["IDSIMPLE_API_KEY"]
  config.signing_secret = ENV["IDSIMPLE_SIGNING_SECRET"]
end
```

## Rack
To add `idsimple-rack` to a Rack application, you need to `run` `Idsimple::Rack::AuthenticatorApp`,
at `Idsimple::Rack.configuration.authenticate_path`, `use` `Idsimple::Rack::ValidatorMiddleware` in your stack,
and set your [configuration options](#configuration).

```ruby
# config.ru

class Application
  def call(_)
    status  = 200
    headers = { "Content-Type" => "text/html" }
    body    = ["<html><body>yay!!!</body></html>"]

    [status, headers, body]
  end
end

Idsimple::Rack.configure do |config|
  config.app_id = ENV["IDSIMPLE_APP_ID"]
  config.api_key = ENV["IDSIMPLE_API_KEY"]
  config.signing_secret = ENV["IDSIMPLE_SIGNING_SECRET"]
end

App = Rack::Builder.new do
  use Rack::Reloader, 0

  map Idsimple::Rack.configuration.authenticate_path do
    run Idsimple::Rack::AuthenticatorApp
  end

  use Idsimple::Rack::ValidatorMiddleware

  run Application.new
end.to_app

run App
```

You can see a working example of this in the
[`idsimple-rack` repo](https://github.com/idsimple/idsimple-rack/blob/main/example_app/config.ru).


## Configuration
`idsimple-rack` can be configured by calling `Idsimple::Rack.configure` with a block like so:

```ruby
Idsimple::Rack.configure do |config|
  config.app_id = ENV["IDSIMPLE_APP_ID"]
  config.api_key = ENV["IDSIMPLE_API_KEY"]
  config.signing_secret = ENV["IDSIMPLE_SIGNING_SECRET"]
end
```

### Configuration Options
#### `app_id`
The idsimple App ID. This can be found in the "Keys & Secrets" tab for your app in idsimple.

- Type: String
- Optional: No


#### `api_key`
The idsimple App Session API Key. This is generated and shown when you create an idsimple app.
You can view the prefix of the App Session API Key in the "Keys & Secrets" tab for your app in idsimple.

- Type: String
- Optional: No

#### `signing_secret`
The idsimple App signing secret. This is generated and shown when you create an idsimple app.
You can view the prefix of the signing secret in the "Keys & Secrets" tab for your app in idsimple.

- Type: String
- Optional: No

#### `get_access_token`
Function for retrieving the access token from a store.
By default, the access token is retrieved from an [HTTP cookie](https://en.wikipedia.org/wiki/HTTP_cookie).

- Type: Lambda
- Optional: Yes
- Default:
```ruby
-> (req) {
  req.cookies[DEFAULT_COOKIE_NAME]
}
```


#### `set_access_token`
Function for setting the access token in a store.
By default, the access token is stored in an [HTTP cookie](https://en.wikipedia.org/wiki/HTTP_cookie).

- Type: Lambda
- Optional: Yes
- Default:
```ruby
-> (req, res, access_token, decoded_access_token) {
  res.set_cookie(DEFAULT_COOKIE_NAME, {
    value: access_token,
    expires: Time.at(decoded_access_token[0]["exp"]),
    httponly: true,
    path: "/"
  })
}
```

#### `remove_access_token`
Function for removing the access token from a store.

- Type: Lambda
- Optional: Yes
- Default:
```ruby
-> (req, res) {
  res.delete_cookie(DEFAULT_COOKIE_NAME)
}
```

#### `authenticate_path`
Path to initiate a new session with an access token.
This is the location to which idsimple will redirect the user once a new access token is generated.
`Idsimple::Rack::AuthenticatorApp` should be mounted at this path.

- Type: String
- Optional: Yes
- Default: `/idsimple/session`

#### `after_authenticated_path`
Path to redirect the user after they've been authenticated.

- Type: String
- Optional: Yes
- Default: `/`

#### `skip_on`
Function used to conditionally skip validation by the middleware.
By returning `true`, `Idsimple::Rack::ValidatorMiddleware` will skip
validation for that request.

- Type: Lambda
- Optional: Yes
- Default: `nil`

Example:

```ruby
-> (req) {
  req.path == "/webhooks"
}
```

#### `logger`
The `logger` option allows you to set your own custom logger.

- Type: Logger
- Optional: yes
- Default:
```ruby
logger = Logger.new(STDOUT)
logger.level = Logger::INFO
default_formatter = Logger::Formatter.new
logger.formatter = proc do |severity, datetime, progname, msg|
  "Idsimple::Rack #{default_formatter.call(severity, datetime, progname, msg)}"
end
```

#### `enabled`
Boolean indicating whether the idsimple middleware should be enabled.

- Type: Boolean
- Optional: true
- Default: true

#### `unauthorized_response`
Function for customizing the unauthorized response sent by the middleware.

- Type: Lambda
- Optional: Yes
- Default:
```ruby
-> (req, res) {
  res.status = 401
  res.content_type = "text/html"
  res.body = ["UNAUTHORIZED"]
}
```

#### `redirect_to_authenticate`
Boolean indicating whether the middleware should redirect users
to `app.idsimple.io` to authenticate. If set to `false`, unauthorized users
will receive a `401 UNAUTHORIZED` response when visiting your app
instead of being redirected to `app.idsimple.io`.

- Type: Boolean
- Optional: Yes
- Default: `true`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/idsimple/idsimple-rack. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/idsimple/idsimple-rack/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Idsimple::Rack project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/idsimple/idsimple-rack/blob/master/CODE_OF_CONDUCT.md).
