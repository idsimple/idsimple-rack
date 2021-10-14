require "rack"
require "idsimple/rack/access_token_validator"
require "idsimple/rack/helper"

module Idsimple
  module Rack
    class AuthenticatorApp
      extend Helper

      def self.call(env)
        return ["404", { "Content-Type" => "text/html" }, ["NOT FOUND"]] unless configuration.enabled?

        req = ::Rack::Request.new(env)

        if (access_token = req.params["access_token"])
          logger.debug("Found access token")

          decoded_access_token = decode_access_token(access_token, signing_secret)
          logger.debug("Decoded access token")

          validation_result = AccessTokenValidator.validate_unused_token_custom_claims(decoded_access_token, req)
          if validation_result.invalid?
            logger.warn("Attempted to access with invalid token: #{validation_result.full_error_message}")
            return unauthorized_response(req)
          end

          use_token_response = api.use_token(decoded_access_token[0]["jti"])
          if use_token_response.fail?
            logger.warn("Use token response error. HTTP status #{use_token_response.status}. #{use_token_response.full_error_message}")
            return unauthorized_response(req)
          end

          new_access_token = use_token_response.body["access_token"]
          new_decoded_access_token = decode_access_token(new_access_token, signing_secret)

          res = ::Rack::Response.new
          res.redirect(configuration.after_authenticated_path)
          set_access_token(req, res, new_access_token, new_decoded_access_token)
          res.finish
        else
          unauthorized_response(req)
        end
      rescue JWT::DecodeError => e
        logger.warn("Error while decoding token: #{e.class} - #{e.message}")
        unauthorized_response(req)
      end
    end
  end
end
