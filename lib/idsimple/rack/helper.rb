require "idsimple/rack/access_token_helper"
require "idsimple/rack/api"

module Idsimple
  module Rack
    module Helper
      def configuration
        Idsimple::Rack.configuration
      end

      def logger
        configuration.logger
      end

      def signing_secret
        configuration.signing_secret
      end

      def unauthorized_response(req, res = ::Rack::Response.new)
        logger.info("Unauthorized")
        configuration.unauthorized_response.call(req, res)
        res.finish
      end

      def redirect_to_authenticate_or_unauthorized_response(req, res = ::Rack::Response.new)
        issuer = configuration.issuer
        app_id = configuration.app_id
        access_attempt = req.params["idsimple_access_attempt"]

        if configuration.redirect_to_authenticate && issuer && app_id && !access_attempt
          logger.info("Redirecting to authenticate")
          access_url = "#{issuer}/apps/#{app_id}/access?return_to=#{req.fullpath}"
          res.redirect(access_url)
          res.finish
        else
          unauthorized_response(req, res)
        end
      end

      def get_access_token(req)
        configuration.get_access_token.call(req)
      end

      def set_access_token(req, res, new_access_token, new_decoded_access_token)
        configuration.set_access_token.call(req, res, new_access_token, new_decoded_access_token)
      end

      def remove_access_token(req, res)
        configuration.remove_access_token.call(req, res)
      end

      def decode_access_token(access_token, signing_secret)
        AccessTokenHelper.decode(access_token, signing_secret, {
          iss: configuration.issuer,
          aud: configuration.app_id
        })
      end

      def api
        @api ||= Idsimple::Rack::Api.new(
          configuration.api_base_url,
          configuration.api_base_path,
          configuration.api_key
        )
      end
    end
  end
end
