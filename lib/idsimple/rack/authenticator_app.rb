require "rack"
require "idsimple/rack/access_token_validator"
require "idsimple/rack/helper"

module Idsimple
  module Rack
    class AuthenticatorApp
      extend Idsimple::Rack::Helper

      UNAUTHORIZED_RESPONSE = ["401", { "Content-Type" => "text/html" }, ["UNAUTHORIZED"]].freeze

      def self.call(env)
        req = ::Rack::Request.new(env)

        if (access_token = req.params["access_token"])
          logger.debug("Found access_token token")

          decoded_access_token = decode_access_token(access_token, signing_secret)
          logger.debug("Decoded access_token token")

          validation_result = AccessTokenValidator.validate_unused_token_custom_claims(decoded_access_token, req)
          if validation_result.invalid?
            logger.warn("Attempted to access with invalid token: #{validation_result.full_error_message}")
            return UNAUTHORIZED_RESPONSE
          end

          use_token_response = api.use_token(decoded_access_token[0]["jti"])
          if use_token_response.fail?
            logger.warn(use_token_response.body) if use_token_response.body
            return UNAUTHORIZED_RESPONSE
          end

          new_access_token = use_token_response.body["access_token"]
          new_decoded_access_token = decode_access_token(new_access_token, signing_secret)

          res = ::Rack::Response.new
          res.redirect(configuration.after_authenticated_path)
          configuration.set_access_token.call(env, res, new_access_token, new_decoded_access_token)
          res.finish
        else
          UNAUTHORIZED_RESPONSE
        end
      rescue JWT::DecodeError => e
        logger.warn("Error while decoding token: #{e.class} - #{e.message}")
        UNAUTHORIZED_RESPONSE
      end
    end
  end
end
