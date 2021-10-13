require "idsimple/rack/validator_middleware"
require "idsimple/rack/authenticator_app"

module Idsimple
  module Rack
    class Railtie < ::Rails::Engine
      initializer "idsimple-rack.configure" do |app|
        app.routes.append do
          mount Idsimple::RackPlugin::AuthenticatorApp
        end

        app.middleware.use(Idsimple::Rack::ValidatorMiddleware)
      end
    end
  end
end
