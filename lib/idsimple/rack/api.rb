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
        Result.new(response)
      end

      def refresh_token(token_id)
        response = http_client.patch("/api/v1/sessions/#{token_id}/refresh", "")
        Result.new(response)
      end

      class Result
        attr_reader :response

        def initialize(response)
          @response = response
        end

        def success?
          response.kind_of?(Net::HTTPSuccess)
        end

        def fail?
          !success?
        end

        def body
          @body ||= JSON.parse(response.body) if response.body
        end
      end
    end
  end
end
