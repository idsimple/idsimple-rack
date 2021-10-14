require "idsimple/rack"
require "rack/test"
require "pry"
require "pry-byebug"
require "helpers/token_helper"
require "helpers/api_helper"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include TokenHelper
  config.include ApiHelper
end
