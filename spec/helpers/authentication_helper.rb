module AuthenticationHelper
  def authenticate(additional_claims = {})
    payload = generate_token_payload(additional_claims)
    used_payload = payload.merge("idsimple.used_at" => Time.now.to_i)
    expect_any_instance_of(Idsimple::Rack::Api).to receive(:use_token) do
      mocked_api_result(200, { "access_token" => encode_token(used_payload) })
    end

    get "#{authenticate_path}?access_token=#{encode_token(payload)}"
    used_payload
  end
end
