module Idsimple
  module Rack
    class AccessTokenValidationResult
      attr_reader :errors

      def initialize
        @errors = []
      end

      def valid?
        errors.empty?
      end

      def invalid?
        !valid?
      end

      def add_error(msg)
        @errors << msg
      end

      def full_error_message
        "#{errors.join(". ")}." unless errors.empty?
      end
    end
  end
end
