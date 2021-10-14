require "spec_helper"

RSpec.describe Idsimple::Rack::ValidatorMiddleware do
  include Rack::Test::Methods

  let(:configuration) { Idsimple::Rack.configuration }
  let(:authenticate_path) { configuration.authenticate_path }
  let(:signing_secret) { "123" }

  let(:logger) { Logger.new(IO::NULL) }

  let(:app) do
    Rack::Builder.app do
      use Idsimple::Rack::ValidatorMiddleware

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

  describe "#call" do
    it "returns unauthorized response when not authenticated" do
      get "/"
      expect(last_response.unauthorized?).to be true
    end

    it "skips validator middleware when attempting to authenticate" do
      expect(logger).to receive(:debug).with("Attempting to authenticate. Skipping validation.")
      get authenticate_path
      expect(last_response.unauthorized?).to be true
    end

    it "skips validator middleware when Configuration#skip_on returns true" do
      configuration.skip_on = ->(req) {
        req.path == "/skip"
      }

      expect(logger).to receive(:debug).with("Skipping validator due to skip_on rules")
      get "/skip"
      expect(last_response.ok?).to be true
      expect(last_response.body).to eq("OK")

      get "/"
      expect(last_response.unauthorized?).to be true
    end


    it "returns unauthorized response when custom claim validation fails" do
      authenticate

      expect(Idsimple::Rack::AccessTokenValidator).to receive(:validate_used_token_custom_claims) do
        result = Idsimple::Rack::AccessTokenValidationResult.new
        result.add_error("This is an error")
        result
      end

      expect(logger).to receive(:warn).with("Attempted to access with invalid used token: This is an error.")

      follow_redirect!

      expect(last_response.unauthorized?).to be true
    end

    it "allows access with valid token" do
      authenticate
      follow_redirect!
      expect(last_response.ok?).to be true
      expect(last_response.body).to eq("OK")
    end
  end
end
