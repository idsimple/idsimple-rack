require "spec_helper"

RSpec.describe Idsimple::Rack::AuthenticatorApp do
  include Rack::Test::Methods

  let(:authenticate_path) { Idsimple::Rack.configuration.authenticate_path }
  let(:signing_secret) { "123" }

  let(:logger) { Logger.new(IO::NULL) }

  let(:app) do
    Rack::Builder.app do
      map Idsimple::Rack.configuration.authenticate_path do
        run Idsimple::Rack::AuthenticatorApp
      end

      run lambda { |env| [200, { "Content-Type" => "text/plain" }, ["OK"]] }
    end
  end

  before do
    Idsimple::Rack.configure do |config|
      config.logger = logger
      config.signing_secret = signing_secret
    end
  end

  after { Idsimple::Rack.reset_configuration }

  describe ".call" do
    it "returns unauthorized response if request missing access token" do
      get authenticate_path
      expect(last_response.unauthorized?).to be true
    end

    it "returns unauthorized response when access token can't be decoded" do
      expect(logger).to receive(:warn).with(/Error while decoding token: JWT::DecodeError - Not enough or too many segments/)
      get "#{authenticate_path}?access_token=123"
      expect(last_response.unauthorized?).to be true
    end

    it "returns unauthorized response when custom claim validation fails" do
      expect(Idsimple::Rack::AccessTokenValidator).to receive(:validate_unused_token_custom_claims) do
        result = Idsimple::Rack::AccessTokenValidationResult.new
        result.add_error("This is an error")
        result
      end

      expect(logger).to receive(:warn).with("Attempted to access with invalid token: This is an error.")

      payload = generate_token_payload
      get "#{authenticate_path}?access_token=#{encode_token(payload)}"
      expect(last_response.unauthorized?).to be true
    end

    it "returns unauthorized response when use_token api call fails" do
      payload = generate_token_payload
      expect_any_instance_of(Idsimple::Rack::Api).to receive(:use_token) do
        mocked_api_result(422, { "errors" => ["An error occurred"] })
      end

      expect(logger).to receive(:warn).with("Use token response error. HTTP status 422. An error occurred.")

      get "#{authenticate_path}?access_token=#{encode_token(payload)}"
      expect(last_response.unauthorized?).to be true
    end

    it "redirects to authenticated path with valid access token" do
      authenticate
      expect(last_response.redirect?).to be true
      expect(last_response.location).to eq(Idsimple::Rack.configuration.after_authenticated_path)
    end

    context "when disabled" do
      before { Idsimple::Rack.configuration.enabled = false }

      it "returns a 404, not found" do
        get authenticate_path
        expect(last_response.not_found?).to be true
      end
    end
  end
end
