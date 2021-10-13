require_relative 'lib/idsimple/rack/version'

Gem::Specification.new do |spec|
  spec.name          = "idsimple-rack"
  spec.version       = Idsimple::Rack::VERSION
  spec.authors       = ["Ari Summer"]
  spec.email         = ["aribsummer@gmail.com"]

  spec.summary       = "Rack middleware for idsimple integration."
  spec.homepage      = "https://idsimple.com"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/idsimple/idsimple-rack"
  spec.metadata["changelog_uri"] = "https://github.com/idsimple/idsimple-rack/CHANGELOG.md"

  spec.files         = Dir.glob("{bin,lib}/**/*") + %w(Rakefile README.md LICENSE.txt idsimple-rack.gemspec)
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rack", ">= 1.0", "< 3"
  spec.add_runtime_dependency "jwt", "~> 2.0"
end
