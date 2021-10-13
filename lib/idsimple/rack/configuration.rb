require "logger"
require "rack"

module Idsimple
  module Rack
    class Configuration
      attr_accessor :get_access_token, :set_access_token, :signing_secret,
        :authenticate_path, :issuer, :api_base_url, :after_authenticated_path,
        :app_id, :skip_on, :logger

      def initialize
        set_defaults
      end

      private

      def set_defaults
        @authenticate_path = "/idsimple/session"
        @after_authenticated_path = "/"
        @issuer = "https://app.idsimple.com"
        @api_base_url = "https://app.idsimple.com"
        @app_id = nil
        @skip_on = nil
        @signing_secret = nil
        @get_access_token = method(:default_access_token_getter)
        @set_access_token = method(:default_access_token_setter)
        @logger = Logger.new(STDOUT)
      end

      def default_access_token_getter(env)
        req = Rack::Request.new(env)
        req.cookies["idsimple.access_token"]
      end

      def default_access_token_setter(env, res, access_token, decoded_access_token)
        res.set_cookie("idsimple.access_token", {
          value: access_token,
          expires: Time.at(decoded_access_token[0]["exp"]),
          httponly: true,
          path: "/"
        })
      end
    end
  end
end
