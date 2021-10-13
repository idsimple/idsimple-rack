require "rack"
require "idsimple/rack/access_token_helper"
require "idsimple/rack/access_token_validator"
require "idsimple/rack/api"

module Idsimple
  module Rack
    class AuthenticatorApp
      UNAUTHORIZED_RESPONSE = ["401", { "Content-Type" => "text/html" }, ["UNAUTHORIZED"]].freeze

      def self.call(env)
        req = Rack::Request.new(env)

        if (access_token = req.params["access_token"])
          logger.info("Found access_token token")

          decoded_access_token = decode_access_token(access_token, signing_secret)
          logger.info("Decoded access_token token")

          validation_result = AccessTokenValidator.validate_unused_token_custom_claims(decoded_access_token, req)
          if validation_result.invalid?
            logger.info("Attempted to access with invalid token: #{validation_result.errors}")
            return UNAUTHORIZED_RESPONSE
          end

          use_token_response = api.use_token(decoded_access_token[0]["jti"])
          if !use_token_response.kind_of?(Net::HTTPSuccess)
            logger.info(use_token_response.body) if use_token_response.body
            return UNAUTHORIZED_RESPONSE
          end

          new_access_token = use_token_response.body["access_token"]
          new_decoded_access_token = decode_access_token(new_access_token, signing_secret)

          res = Rack::Response.new
          res.redirect(configuration.after_authenticated_path)
          configuration.set_access_token.call(env, res, new_access_token, new_decoded_access_token)
          res.finish
        else
          return UNAUTHORIZED_RESPONSE
        end
      rescue JWT::DecodeError => e
        logger.info("Error while decoding token: #{e.class} - #{e.message}")
        return UNAUTHORIZED_RESPONSE
      end

      def self.configuration
        Idsimple::Rack.configuration
      end

      def self.logger
        configuration.logger
      end

      def self.signing_secret
        configuration.signing_secret
      end

      def self.decode_access_token(access_token, signing_secret)
        AccessTokenHelper.decode(access_token, signing_secret, {
          iss: configuration.issuer,
          aud: configuration.app_id
        })
      end

      def self.api
        @api ||= Idsimple::Rack::Api.new(configuration.api_base_url)
      end
    end
  end
end
