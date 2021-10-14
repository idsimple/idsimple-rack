require "spec_helper"

RSpec.describe Idsimple::Rack::ValidatorMiddleware do
  include Rack::Test::Methods

  let(:authenticate_path) { Idsimple::Rack.configuration.authenticate_path }
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
  end
end
