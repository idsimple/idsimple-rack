require "spec_helper"

RSpec.describe Idsimple::Rack::AccessTokenValidator do
  describe ".validate_used_token_custom_claims" do
    describe "validate IP claim" do
      it "it returns invalid result when IP mismatch" do
        result = described_class.validate_used_token_custom_claims(
          [{ "idsimple.ip" => "127.0.0.1", "idsimple.used_at" => Time.now.to_i }],
          double(ip: "172.9.0.1")
        )

        expect(result.invalid?).to be true
        expect(result.full_error_message).to include("IP mismatch")
      end

      it "returns valid result when IP matches" do
        result = described_class.validate_used_token_custom_claims(
          [{ "idsimple.ip" => "127.0.0.1", "idsimple.used_at" => Time.now.to_i }],
          double(ip: "127.0.0.1")
        )

        expect(result.valid?).to be true
        expect(result.full_error_message).to be_nil
      end
    end

    describe "validate user agent claim" do
      it "returns invalid result when user agent mismatch" do
        result = described_class.validate_used_token_custom_claims(
          [{ "idsimple.user_agent" => "Chrome", "idsimple.used_at" => Time.now.to_i }],
          double(user_agent: "Safari")
        )

        expect(result.invalid?).to be true
        expect(result.full_error_message).to include("User agent mismatch")
      end

      it "returns valid result when user agent matches" do
        result = described_class.validate_used_token_custom_claims(
          [{ "idsimple.user_agent" => "Chrome", "idsimple.used_at" => Time.now.to_i }],
          double(user_agent: "Chrome")
        )

        expect(result.valid?).to be true
        expect(result.full_error_message).to be_nil
      end
    end

    describe "validate used_at claim" do
      it "returns invalid result when missing used_at claim" do
        result = described_class.validate_used_token_custom_claims(
          [{}],
          double
        )

        expect(result.invalid?).to be true
        expect(result.full_error_message).to include("Missing used_at timestamp")
      end

      it "returns invalid result when used_at is in the future" do
        result = described_class.validate_used_token_custom_claims(
          [{ "idsimple.used_at" => Time.now.to_i + 60 }],
          double
        )

        expect(result.invalid?).to be true
        expect(result.full_error_message).to include("Invalid used_at timestamp")
      end
    end
  end

  describe ".validate_unused_token_custom_claims" do
  end
end
