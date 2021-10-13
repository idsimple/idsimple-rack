require "idsimple/rack/version"
require "idsimple/rack/configuration"
require "idsimple/rack/railtie" if defined?(::Rails)

module Idsimple
  module Rack
    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.reset_configuration
      @configuration = Configuration.new
    end

    def self.configure
      yield(configuration)
    end
  end
end
