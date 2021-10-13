require "spec_helper"

RSpec.describe Idsimple::Rack::AuthenticatorApp do
  include Rack::Test::Methods

  let(:authenticate_path) { Idsimple::Rack.configuration.authenticate_path }

  let(:app) do
    Rack::Builder.app do
      map Idsimple::Rack.configuration.authenticate_path do
        run Idsimple::Rack::AuthenticatorApp
      end

      run lambda { |env| [200, { "Content-Type" => "text/plain" }, ["OK"]] }
    end
  end

  let(:logger) { Logger.new(IO::NULL) }

  before do
    Idsimple::Rack.configure do |config|
      config.logger = logger
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
  end
end
