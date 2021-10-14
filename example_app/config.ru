$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rack"
require "logger"
require "idsimple/rack"

class Application
  def call(_)
    status  = 200
    headers = { "Content-Type" => "text/html" }
    body    = ["<html><body>yay!!!</body></html>"]

    [status, headers, body]
  end
end

Idsimple::Rack.configure do |config|
  config.app_id = ENV["APP_ID"]
  config.signing_secret = ENV["SIGNING_SECRET"]
  config.issuer = "http://localhost:3000"
  config.api_base_url = "http://localhost:3000"
  logger = Logger.new(STDOUT)
  logger.level = Logger::DEBUG
  config.logger = logger
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
