require "idsimple/rack/access_token_validation_result"

module Idsimple
  module Rack
    class AccessTokenValidator
      def self.validate_used_token_custom_claims(decoded_token, req)
        token_payload = decoded_token[0]
        ip = token_payload["ip"]
        user_agent = token_payload["user_agent"]
        used_at = token_payload["used_at"]

        result = AccessTokenValidationResult.new

        if ip && req.ip != ip
          result.add_error("IP mismatch")
        end

        if user_agent && req.user_agent != user_agent
          result.add_error("User agent mismatch")
        end

        result.add_error("Missing used_at timestamp") if !used_at
        result.add_error("Invalid used_at timestamp") if used_at && used_at > Time.now.to_i

        result
      end

      def self.validate_unused_token_custom_claims(decoded_token, req)
        token_payload = decoded_token[0]
        bf = token_payload["bf"]
        used_at = token_payload["used_at"]
        ip = token_payload["ip"]
        user_agent = token_payload["user_agent"]

        result = AccessTokenValidationResult.new

        if ip && req.ip != ip
          result.add_error("IP mismatch")
        end

        if user_agent && req.user_agent != user_agent
          result.add_error("User agent mismatch")
        end

        if bf && Time.now.to_i > bf
          result.add_error("Token must be used prior to before claim")
        end

        result.add_error("Token already used") if used_at

        result
      end
    end
  end
end
