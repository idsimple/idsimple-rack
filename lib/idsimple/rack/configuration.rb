require "rack"
require "logger"

module Idsimple
  module Rack
    class Configuration
      DEFAULT_COOKIE_NAME = "idsimple.access_token"

      attr_accessor :get_access_token, :set_access_token, :remove_access_token, :signing_secret,
        :authenticate_path, :issuer, :api_base_url, :api_base_path, :after_authenticated_path,
        :app_id, :skip_on, :logger, :enabled, :unauthorized_response, :api_key,
        :redirect_to_authenticate

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
        @issuer = "https://app.idsimple.io"
        @api_base_url = "https://api.idsimple.io"
        @api_base_path = "/v1"
        @app_id = nil
        @skip_on = nil
        @signing_secret = nil
        @api_key = nil
        @get_access_token = method(:default_access_token_getter)
        @set_access_token = method(:default_access_token_setter)
        @remove_access_token = method(:default_access_token_remover)
        @unauthorized_response = method(:default_unauthorized_response)
        @redirect_to_authenticate = true

        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        default_formatter = Logger::Formatter.new
        logger.formatter = proc do |severity, datetime, progname, msg|
          "Idsimple::Rack #{default_formatter.call(severity, datetime, progname, msg)}"
        end
        @logger = logger
      end

      def default_unauthorized_response(req, res)
        res.status = 401
        res.content_type = "text/html"
        res.body = ["UNAUTHORIZED"]
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

      def default_access_token_remover(req, res)
        res.delete_cookie(DEFAULT_COOKIE_NAME)
      end
    end
  end
end
