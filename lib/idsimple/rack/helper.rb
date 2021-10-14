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

      def unauthorized_response(req)
        configuration.unauthorized_response.call(req)
      end

      def get_access_token(req)
        configuration.get_access_token.call(req)
      end

      def set_access_token(req, res, new_access_token, new_decoded_access_token)
        configuration.set_access_token.call(req, res, new_access_token, new_decoded_access_token)
      end

      def decode_access_token(access_token, signing_secret)
        AccessTokenHelper.decode(access_token, signing_secret, {
          iss: configuration.issuer,
          aud: configuration.app_id
        })
      end

      def api
        @api ||= Idsimple::Rack::Api.new(configuration.api_base_url)
      end
    end
  end
end
