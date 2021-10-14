module AuthenticationHelper
  def authenticate
    payload = generate_token_payload
    expect_any_instance_of(Idsimple::Rack::Api).to receive(:use_token) do
      mocked_api_result(200, { "access_token" => encode_token(payload.merge("used_at" => Time.now.to_i)) })
    end

    get "#{authenticate_path}?access_token=#{encode_token(payload)}"
  end
end
