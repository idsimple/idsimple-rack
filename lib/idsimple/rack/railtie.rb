require "idsimple/rack/validator_middleware"
require "idsimple/rack/authenticator_app"

module Idsimple
  module Rack
    class Railtie < ::Rails::Engine
      initializer "idsimple-rack.configure" do |app|
        app.routes.append do
          mount Idsimple::Rack::AuthenticatorApp, at: Idsimple::Rack.configuration.authenticate_path
        end

        app.middleware.use(Idsimple::Rack::ValidatorMiddleware)
      end
    end
  end
end
