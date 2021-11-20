require "net/http"
require "json"

module Idsimple
  module Rack
    class Api
      attr_reader :base_url

      def initialize(base_url, api_key)
        @base_url = base_url
        @api_key = api_key
      end

      # TODO:
      # - incorporate API secret
      def http_client
        @http_client ||= begin
          uri = URI.parse(base_url)
          client = Net::HTTP.new(uri.host, uri.port)
          client.use_ssl = base_url.start_with?("https")
          client
        end
      end

      def use_token(token_id)
        response = http_client.patch("/api/v1/access_tokens/#{token_id}/use", "", headers)
        Result.new(response)
      end

      def refresh_token(token_id)
        response = http_client.patch("/api/v1/access_tokens/#{token_id}/refresh", "", headers)
        Result.new(response)
      end

      private

      def headers
        {
          "Authorization" => "Bearer #{@api_key}",
          "Content-Type" => "application/json"
        }
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

        def status
          response.code
        end

        def body
          @body ||= JSON.parse(response.body) if response.body
        end

        def full_error_message
          "#{body["errors"].join(". ")}." if body && body["errors"]
        end
      end
    end
  end
end
