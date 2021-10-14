module TokenHelper
  def encode_token(payload, secret = Idsimple::Rack.configuration.signing_secret)
    JWT.encode(
      payload,
      secret,
      "HS256"
    )
  end

  def generate_token_payload(claims = {})
    {
      "jti" => "123",
      "sub" => "123",
      "aud" => "123",
      "iat" => Time.now.to_i,
      "exp" => (Time.now + 60*60).to_i,
      "iss" => Idsimple::Rack.configuration.issuer
    }.merge(claims)
  end
end
