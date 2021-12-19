require "idsimple/rack/access_token_validation_result"

module Idsimple
  module Rack
    class AccessTokenValidator
      def self.validate_used_token_custom_claims(decoded_token, req)
        token_payload = decoded_token[0]
        ip = token_payload["idsimple.ip"]
        user_agent = token_payload["idsimple.user_agent"]
        used_at = token_payload["idsimple.used_at"]

        result = AccessTokenValidationResult.new

        if ip && req.ip != ip
          result.add_error("IP mismatch - Expected: #{ip} Actual: #{req.ip}")
        end

        if user_agent && req.user_agent != user_agent
          result.add_error("User agent mismatch - Expected: #{user_agent} Actual: #{req.user_agent}")
        end

        result.add_error("Missing used_at timestamp") if !used_at
        result.add_error("Invalid used_at timestamp") if used_at && used_at > Time.now.to_i

        result
      end

      def self.validate_unused_token_custom_claims(decoded_token, req)
        token_payload = decoded_token[0]
        use_by = token_payload["idsimple.use_by"]
        used_at = token_payload["idsimple.used_at"]
        ip = token_payload["idsimple.ip"]
        user_agent = token_payload["idsimple.user_agent"]

        result = AccessTokenValidationResult.new

        if ip && req.ip != ip
          result.add_error("IP mismatch - Expected: #{ip} Actual: #{req.ip}")
        end

        if user_agent && req.user_agent != user_agent
          result.add_error("User agent mismatch - Expected: #{user_agent} Actual: #{req.user_agent}")
        end

        if use_by && Time.now.to_i > use_by
          result.add_error("Token must be used prior to before claim")
        end

        result.add_error("Token already used") if used_at

        result
      end
    end
  end
end
