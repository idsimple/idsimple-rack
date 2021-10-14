require "rack"
require "logger"

module Idsimple
  module Rack
    class Configuration
      DEFAULT_COOKIE_NAME = "idsimple.access_token"

      attr_accessor :get_access_token, :set_access_token, :signing_secret,
        :authenticate_path, :issuer, :api_base_url, :after_authenticated_path,
        :app_id, :skip_on, :logger, :enabled, :unauthorized_response

      def initialize
        set_defaults
      end

      def enabled?
        enabled
      end

      private

      def set_defaults
        @enabled = true
        @authenticate_path = "/idsimple/session"
        @after_authenticated_path = "/"
        @issuer = "https://app.idsimple.com"
        @api_base_url = "https://app.idsimple.com"
        @app_id = nil
        @skip_on = nil
        @signing_secret = nil
        @get_access_token = method(:default_access_token_getter)
        @set_access_token = method(:default_access_token_setter)
        @unauthorized_response = method(:default_unauthorized_response)
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::INFO
      end

      def default_unauthorized_response(req)
        ["401", { "Content-Type" => "text/html" }, ["UNAUTHORIZED"]]
      end

      def default_access_token_getter(req)
        req.cookies[DEFAULT_COOKIE_NAME]
      end

      def default_access_token_setter(req, res, access_token, decoded_access_token)
        res.set_cookie(DEFAULT_COOKIE_NAME, {
          value: access_token,
          expires: Time.at(decoded_access_token[0]["exp"]),
          httponly: true,
          path: "/"
        })
      end
    end
  end
end
