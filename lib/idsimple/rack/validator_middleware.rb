require "rack"
require "idsimple/rack/access_token_validator"
require "idsimple/rack/helper"

module Idsimple
  module Rack
    class ValidatorMiddleware
      include Idsimple::Rack::Helper

      UNAUTHORIZED_RESPONSE = ["401", { "Content-Type" => "text/html" }, ["UNAUTHORIZED"]].freeze
      ACCESS_TOKEN_ENV_KEY = "idsimple.access_token"

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        req = ::Rack::Request.new(env)

        if (req.path == configuration.authenticate_path) || (configuration.skip_on && configuration.skip_on.call(req))
          return app.call(env)
        end

        logger.info("Retrieved access_token token from store")
        decoded_access_token = decode_access_token(access_token, signing_secret)
        logger.info("Decoded access_token token")

        validation_result = AccessTokenValidator.validate_used_token_custom_claims(decoded_access_token, req)
        if validation_result.invalid?
          logger.info("Attempted to access with invalid used token: #{validation_result.errors}")
          return UNAUTHORIZED_RESPONSE
        end

        if (refresh_at = decoded_access_token[0]["refresh_at"]) && refresh_at < Time.now.to_i
          jti = decoded_access_token[0]["jti"]
          handle_refresh_access_token(jti, env)
        else
          env[ACCESS_TOKEN_ENV_KEY] = decoded_access_token
          app.call(env)
        end
      end

      def handle_refresh_access_token(jti, env)
        token_refresh_response = api.refresh_token(jti)

        if !token_refresh_response.kind_of?(Net::HTTPSuccess)
          logger.info("Token refresh failed")
          UNAUTHORIZED_RESPONSE
        else
          logger.info("Refreshed access token")
          new_access_token = token_refresh_response.body["access_token"]
          new_decoded_access_token = decode_access_token(new_access_token, signing_secret)
          env[ACCESS_TOKEN_ENV_KEY] = new_decoded_access_token
          status, headers, body = app.call(env)
          res = ::Rack::Response.new(body, status, headers)
          set_access_token.call(env, res, new_access_token, new_decoded_access_token)
          res.finish
        end
      end
    end
  end
end
