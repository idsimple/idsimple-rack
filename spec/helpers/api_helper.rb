module ApiHelper
  def mocked_api_result(status, body = {})
    response = Net::HTTPResponse::CODE_TO_OBJ[status.to_s].new(1.0, status.to_s, "")
    allow(response).to receive(:body) { body.to_json }

    Idsimple::Rack::Api::Result.new(response)
  end
end
