require "net/http"
require "json"

module Idsimple
  module Rack
    class Api
      attr_reader :base_url

      def initialize(base_url)
        @base_url = base_url
      end

      def http_client
        @http_client ||= begin
          uri = URI.parse(base_url)
          Net::HTTP.new(uri.host, uri.port)
        end
      end

      # TODO:
      # - handle unsuccessful response
      # - incorporate API secret
      def use_token(token_id)
        response = http_client.patch("/api/v1/sessions/#{token_id}/use", "")
        response.body = JSON.parse(response.body) if response.body
        response
      end

      def refresh_token(token_id)
        response = http_client.patch("/api/v1/sessions/#{token_id}/refresh", "")
        response.body = JSON.parse(response.body) if response.body
        response
      end
    end
  end
end
