require "jwt"

module Idsimple
  module Rack
    class AccessTokenHelper
      def self.decode(access_token, signing_secret, options = {})
        JWT.decode(access_token, signing_secret, true, {
          algorithm: "HS256",
          verify_iss: true,
          verify_aud: true,
          verify_iat: true
        }.merge(options))
      end
    end
  end
end
