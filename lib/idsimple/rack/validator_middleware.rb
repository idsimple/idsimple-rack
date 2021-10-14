require "rack"
require "idsimple/rack/access_token_validator"
require "idsimple/rack/helper"

module Idsimple
  module Rack
    class ValidatorMiddleware
      include Helper

      DECODED_ACCESS_TOKEN_ENV_KEY = "idsimple.decoded_access_token"

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        return app.call(env) unless configuration.enabled?

        req = ::Rack::Request.new(env)

        if req.path == configuration.authenticate_path
          logger.debug("Attempting to authenticate. Skipping validation.")
          return app.call(env)
        end

        if configuration.skip_on && configuration.skip_on.call(req)
          logger.debug("Skipping validator due to skip_on rules")
          return app.call(env)
        end

        access_token = get_access_token(req)

        return unauthorized_response(req) unless access_token

        logger.debug("Retrieved access token from store")
        decoded_access_token = decode_access_token(access_token, signing_secret)
        logger.debug("Decoded access token")

        validation_result = AccessTokenValidator.validate_used_token_custom_claims(decoded_access_token, req)
        if validation_result.invalid?
          logger.warn("Attempted to access with invalid used token: #{validation_result.full_error_message}")
          return unauthorized_response(req)
        end

        if (refresh_at = decoded_access_token[0]["idsimple.refresh_at"]) && refresh_at < Time.now.to_i
          logger.debug("Refreshing access token")
          jti = decoded_access_token[0]["jti"]
          handle_refresh_access_token(jti, req)
        else
          env[DECODED_ACCESS_TOKEN_ENV_KEY] = decoded_access_token
          app.call(env)
        end
      rescue JWT::DecodeError => e
        logger.warn("Error while decoding token: #{e.class} - #{e.message}")
        unauthorized_response(req)
      end

      private

      def handle_refresh_access_token(jti, req)
        token_refresh_response = api.refresh_token(jti)

        if token_refresh_response.fail?
          logger.warn("Token refresh failed")
          unauthorized_response(req)
        else
          logger.debug("Refreshed access token")
          new_access_token = token_refresh_response.body["access_token"]
          new_decoded_access_token = decode_access_token(new_access_token, signing_secret)
          req.env[DECODED_ACCESS_TOKEN_ENV_KEY] = new_decoded_access_token
          status, headers, body = app.call(req.env)
          res = ::Rack::Response.new(body, status, headers)
          set_access_token(req, res, new_access_token, new_decoded_access_token)
          res.finish
        end
      end
    end
  end
end
